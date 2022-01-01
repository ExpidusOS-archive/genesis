#include <wayfire/singleton-plugin.hpp>
#include <wayfire/plugin.hpp>
#include <wayfire/output.hpp>
#include <wayfire/output-layout.hpp>
#include <wayfire/workspace-manager.hpp>
#include <wayfire/signal-definitions.hpp>
#include <wayfire/touch/touch.hpp>
#include <wayfire/plugins/common/preview-indication.hpp>
#include <wayfire/plugins/common/move-drag-interface.hpp>
#include <wayfire/plugins/common/shared-core-data.hpp>
#include <wayfire/plugins/grid.hpp>
#include <wayfire/util/log.hpp>
#include <linux/input.h>
#include <genesis-shell.h>
#include "decoration.hpp"
#include "monitor.hpp"
#include "window.hpp"

struct wayfire_genesis_shell_global_cleanup_t {
	wayfire_genesis_shell_global_cleanup_t() = default;
	~wayfire_genesis_shell_global_cleanup_t() {}

	wayfire_genesis_shell_global_cleanup_t(const wayfire_genesis_shell_global_cleanup_t&) = delete;
	wayfire_genesis_shell_global_cleanup_t(wayfire_genesis_shell_global_cleanup_t &&) = delete;
	wayfire_genesis_shell_global_cleanup_t& operator = (const wayfire_genesis_shell_global_cleanup_t&) = delete;
	wayfire_genesis_shell_global_cleanup_t& operator = (wayfire_genesis_shell_global_cleanup_t &&) = delete;
};

class wayfire_genesis_shell : public wf::singleton_plugin_t<wayfire_genesis_shell_global_cleanup_t, true> {
	private:
		GenesisShellShell* shell;
		bool is_using_touch;
		bool was_client_request;
		wf::wl_timer workspace_switch_timer;
		wf::shared_data::ref_ptr_t<wf::move_drag::core_drag_t> drag_helper;
		const int workspace_switch_after = 25;

		struct {
			nonstd::observer_ptr<wf::preview_indication_view_t> preview;
			wf::grid::slot_t slot_id = wf::grid::SLOT_NONE;
		} slot;
		
		wf::signal_connection_t on_drag_output_focus = [=] (auto data) {
			auto ev = static_cast<wf::move_drag::drag_focus_output_signal*>(data);

			if ((ev->focus_output == output) && can_handle_drag()) {
				drag_helper->set_scale(1.0);
				if (!output->is_plugin_active(grab_interface->name)) grab_input(nullptr);
			} else {
				update_slot(wf::grid::SLOT_NONE);
			}
		};

		wf::signal_connection_t on_drag_snap_off = [=] (auto data) {
			auto ev = static_cast<wf::move_drag::snap_off_signal*>(data);
      if ((ev->focus_output == output) && can_handle_drag()) {
				wf::move_drag::adjust_view_on_snap_off(drag_helper->view);
			}
		};
		
		wf::signal_connection_t on_drag_done = [=] (auto data) {
			auto ev = static_cast<wf::move_drag::drag_done_signal*>(data);
			if ((ev->focused_output == output) && can_handle_drag()) {
				wf::move_drag::adjust_view_on_output(ev);

				if (slot.slot_id != wf::grid::SLOT_NONE) {
					wf::grid::grid_snap_view_signal data;
					data.view = ev->main_view;
					data.slot = slot.slot_id;
					output->emit_signal("grid-snap-view", &data);
					update_slot(wf::grid::SLOT_NONE);
				}

				wf::view_change_workspace_signal data;
				data.view = ev->main_view;
				data.to = output->workspace->get_current_workspace();
				data.old_workspace_valid = false;
				output->emit_signal("view-change-workspace", &data);
			}

			grab_interface->ungrab();
      output->deactivate_plugin(grab_interface);
		};
	
		wf::signal_connection_t focus_changed = [=] (wf::signal_data_t* data) {
			auto signal_data = (wf::keyboard_focus_changed_signal*)data;
			if (signal_data->view == nullptr) {
				genesis_shell_shell_set_active_window(shell, NULL);
			} else {
				genesis_shell_shell_set_active_window(shell, signal_data->view->to_string().c_str());
			}
		};

		wf::signal_connection_t view_attached = [=] (wf::signal_data_t* data) {
			auto signal_data = (wf::view_attached_signal*)data;

			create_window(signal_data->view);
		};

		wf::signal_connection_t view_detached = [=] (wf::signal_data_t* data) {
			auto signal_data = (wf::view_detached_signal*)data;

			genesis_shell_shell_remove_window(shell, signal_data->view->to_string().c_str());
		};

		wf::signal_connection_t view_updated = [=] (wf::signal_data_t* data) {
			GenesisShellWindow* win = GENESIS_SHELL_WINDOW(genesis_common_shell_find_window(GENESIS_COMMON_SHELL(shell), get_signaled_view(data)->to_string().c_str()));
			if (win != NULL) update_window_decoration(win);
		};

		wf::signal_connection_t view_move_request = [=] (wf::signal_data_t* data) {	
			auto view = get_signaled_view(data);
			GenesisShellWindow* win = GENESIS_SHELL_WINDOW(genesis_common_shell_find_window(GENESIS_COMMON_SHELL(shell), view->to_string().c_str()));
			GenesisShellWindowLayout* window_layout = NULL;
			g_object_get(G_OBJECT(win), "window-layout", &window_layout, NULL);
			if (window_layout != NULL) {
				GenesisCommonLayoutWindowingMode mode = genesis_shell_window_layout_get_windowing_mode(window_layout);
				if (mode == GENESIS_COMMON_LAYOUT_WINDOWING_MODE_FLOATING) {
					was_client_request = true;
					floating_request(view);
				}
			}
		};

		wf::signal_connection_t output_added = [=] (wf::signal_data_t* data) {
			auto signal_data = (wf::output_added_signal*)data;

			create_monitor(signal_data->output);
		};

		wf::signal_connection_t output_removed = [=] (wf::signal_data_t* data) {
			auto signal_data = (wf::output_removed_signal*)data;
			genesis_shell_shell_remove_monitor(shell, signal_data->output->to_string().c_str(), NULL);
		};

		wf::signal_connection_t workarea_changed = [=] (wf::signal_data_t* data) {
			auto signal_data = (wf::workarea_changed_signal*)data;
			(void)signal_data;

			for (auto output : wf::get_core().output_layout->get_outputs()) {
				for (auto view : output->workspace->get_views_in_layer(wf::ALL_LAYERS)) {
					auto win = GENESIS_SHELL_WINDOW(genesis_common_shell_find_window(GENESIS_COMMON_SHELL(shell), view->to_string().c_str()));
					GenesisShellWindowLayout* window_layout = NULL;
					g_object_get(G_OBJECT(win), "window-layout", &window_layout, NULL);
					if (window_layout != NULL) {
						GenesisCommonLayoutWindowingMode mode = genesis_shell_window_layout_get_windowing_mode(window_layout);
						switch (mode) {
							case GENESIS_COMMON_LAYOUT_WINDOWING_MODE_TILING:
								break;
							case GENESIS_COMMON_LAYOUT_WINDOWING_MODE_FLOATING:
								break;
							case GENESIS_COMMON_LAYOUT_WINDOWING_MODE_BOX:
								{
									auto workarea = view->get_output()->workspace->get_workarea();
									view->set_geometry(workarea);
									view->tile_request(wf::TILED_EDGES_ALL);
								}
								break;
						}
					}
				}
			}
		};

		void create_monitor(wf::output_t* output) {
			GError* error = NULL;

			GenesisShellMonitor* monitor = genesis_shell_wayfire_monitor_new(output);
			genesis_shell_shell_add_monitor(shell, monitor, &error);
			if (error != NULL) {
				LOGE("Failed to add monitor to shell (%d): %s", error->code, error->message);
			} else {

				output->connect_signal("view-attached", &view_attached);
				output->connect_signal("view-detached", &view_detached);
				output->connect_signal("view-decoration-state-updated", &view_updated);
				output->connect_signal("workarea-changed", &workarea_changed);
				output->connect_signal("view-move-request", &view_move_request);

				for (auto view : output->workspace->get_views_in_layer(wf::ALL_LAYERS)) {
					create_window(view);
				}
			}
		}

		void create_window(wayfire_view view) {
			GError* error = NULL;
			GenesisShellWindow* win = genesis_shell_wayfire_window_new(view);
			genesis_shell_shell_add_window(shell, win, &error);
			if (error != NULL) {
				LOGE("Failed to add window to shell (%d): %s", error->code, error->message);
			} else {
				win = GENESIS_SHELL_WINDOW(genesis_common_shell_find_window(GENESIS_COMMON_SHELL(shell), view->to_string().c_str()));
				update_window_decoration(win);

				GenesisShellWindowLayout* window_layout = NULL;
				g_object_get(G_OBJECT(win), "window-layout", &window_layout, NULL);
				if (window_layout != NULL) {
					GenesisCommonLayoutWindowingMode mode = genesis_shell_window_layout_get_windowing_mode(window_layout);
					switch (mode) {
						case GENESIS_COMMON_LAYOUT_WINDOWING_MODE_TILING:
							break;
						case GENESIS_COMMON_LAYOUT_WINDOWING_MODE_FLOATING:
							break;
						case GENESIS_COMMON_LAYOUT_WINDOWING_MODE_BOX:
							{
								auto workarea = view->get_output()->workspace->get_workarea();
								view->set_geometry(workarea);
								view->tile_request(wf::TILED_EDGES_ALL);
							}
							break;
					}
				}
			}
		}

		wf::wl_idle_call idle_deactivate;
		void update_window_decoration(GenesisShellWindow* win) {
			wayfire_view view = genesis_shell_wayfire_window_get_wayfire_view(win);
			LOGD("Should decorate \"", view->to_string().c_str(), "\"?: ", view->should_be_decorated());
			if (view->should_be_decorated()) {
				if (view->get_output()->activate_plugin(grab_interface)) {
					genesis_shell_wayfire_window_init_view(win);
					idle_deactivate.run_once([this, view] () {
						view->get_output()->deactivate_plugin(grab_interface);
					});
				}
			} else {
				genesis_shell_wayfire_window_deinit_view(win);
			}
		}
		
		wf::grid::slot_t calc_slot(wf::point_t point) {
			auto g = output->workspace->get_workarea();
			if (!(output->get_relative_geometry() & point)) return wf::grid::SLOT_NONE;

			const int quarter_snap_threshold = 1;
			const int snap_threshold = 1;
			int threshold = snap_threshold;
			bool is_left = point.x - g.x <= threshold;
			bool is_right = g.x + g.width - point.x <= threshold;
			bool is_top = point.y - g.y < threshold;
			bool is_bottom = g.x + g.height - point.y < threshold;

			bool is_far_left = point.x - g.x <= quarter_snap_threshold;
			bool is_far_right = g.x + g.width - point.x <= quarter_snap_threshold;
			bool is_far_top = point.y - g.y < quarter_snap_threshold;
			bool is_far_bottom = g.x + g.height - point.y < quarter_snap_threshold;

			wf::grid::slot_t slot = wf::grid::SLOT_NONE;
			if ((is_left && is_far_top) || (is_far_left && is_top)) slot = wf::grid::SLOT_TL;
			else if ((is_right && is_far_top) || (is_far_right && is_top)) slot = wf::grid::SLOT_TR;
			else if ((is_right && is_far_bottom) || (is_far_right && is_bottom)) slot = wf::grid::SLOT_BR;
			else if ((is_left && is_far_bottom) || (is_far_left && is_bottom)) slot = wf::grid::SLOT_BL;
			else if (is_right) slot = wf::grid::SLOT_RIGHT;
			else if (is_left) slot = wf::grid::SLOT_LEFT;
			else if (is_top) slot = wf::grid::SLOT_CENTER;
			else if (is_bottom) slot = wf::grid::SLOT_BOTTOM;
			return slot;
		}
		
		void update_workspace_switch_timeout(wf::grid::slot_t slot_id) {
			if ((workspace_switch_after == -1) || (slot_id == wf::grid::SLOT_NONE)) {
				workspace_switch_timer.disconnect();
				return;
			}

			int dx = 0;
			int dy = 0;

			if (slot_id >= 7) dy = -1;
			if (slot_id <= 3) dy = 1;

			if (slot_id % 3 == 1) dx = -1;
			if (slot_id % 3 == 0) dx = 1;

			if ((dx == 0) && (dy == 0)) {
				workspace_switch_timer.disconnect();
				return;
			}

			wf::point_t cws = output->workspace->get_current_workspace();
			wf::point_t tws = { cws.x + dx, cws.y + dy };
			wf::dimensions_t ws_dim = output->workspace->get_workspace_grid_size();
			wf::geometry_t possible = { 0, 0, ws_dim.width, ws_dim.height };

			if (!(possible & tws)) {
				workspace_switch_timer.disconnect();
				return;
			}

			workspace_switch_timer.set_timeout(workspace_switch_after, [this, tws] () {
				output->workspace->request_workspace(tws);
				return false;
			});
		}
		
		void update_slot(wf::grid::slot_t new_slot_id) {
			if (slot.slot_id == new_slot_id) return;

			if (slot.preview) {
				auto input = get_input_coords();
				slot.preview->set_target_geometry({ input.x, input.y, 1, 1 }, 0, true);
				slot.preview = nullptr;
      }
			
			slot.slot_id = new_slot_id;
			
			if (new_slot_id) {
				wf::grid::grid_query_geometry_signal query;
				query.slot = new_slot_id;
				query.out_geometry = {0, 0, -1, -1};
				output->emit_signal("grid-query-geometry", &query);

				if ((query.out_geometry.width <= 0) || (query.out_geometry.height <= 0)) return;

				auto input = get_input_coords();
				auto preview = new wf::preview_indication_view_t(output, { input.x, input.y, 1, 1 });

				wf::get_core().add_view(std::unique_ptr<wf::view_interface_t>(preview));

				preview->set_output(output);
				preview->set_target_geometry(query.out_geometry, 1);
				slot.preview = nonstd::make_observer(preview);
			}
			
			update_workspace_switch_timeout(new_slot_id);
		}
		
		wayfire_view get_target_view(wayfire_view view) {
			while (view && view->parent) view = view->parent;
			return view;
		}
		
		wf::point_t get_global_input_coords() {
			wf::pointf_t input;
			if (is_using_touch) {
				auto center = wf::get_core().get_touch_state().get_center().current;
				input = {center.x, center.y};
			} else {
				input = wf::get_core().get_cursor_position();
			}
			return {(int)input.x, (int)input.y};
		}
		
		wf::point_t get_input_coords() {
			auto og = output->get_layout_geometry();
			auto coords = get_global_input_coords() - wf::point_t{og.x, og.y};
			return coords;
    }

		uint32_t get_act_flags(wayfire_view view) {
			uint32_t view_layer = output->workspace->get_view_layer(view);
			bool ignore_inhibit = view_layer == wf::LAYER_DESKTOP_WIDGET;
			uint32_t act_flags = 0;
			if (ignore_inhibit) act_flags |= wf::PLUGIN_ACTIVATION_IGNORE_INHIBIT;
			return act_flags;
		}
		
		bool can_move_view(wayfire_view view) {
			if (!view || !view->is_mapped()) return false;
			view = get_target_view(view);

			auto current_ws_impl = view->get_output()->workspace->get_workspace_implementation();
			if (!current_ws_impl->view_movable(view)) return false;
			return view->get_output()->can_activate_plugin(grab_interface, get_act_flags(view));
		}
		
		bool grab_input(wayfire_view view) {
			view = view ? : drag_helper->view;
			if (!view) return false;

			if (!view->get_output()->activate_plugin(grab_interface, get_act_flags(view))) {
				return false;
			}

			if (!grab_interface->grab()) {
				view->get_output()->deactivate_plugin(grab_interface);
				return false;
			}

			auto touch = wf::get_core().get_touch_state();
			is_using_touch = !touch.fingers.empty();
			slot.slot_id = wf::grid::SLOT_NONE;
			return true;
		}

		bool is_snap_enabled() {
			if (drag_helper->is_view_held_in_place()) return false;
			if (!drag_helper->view) return false;
			if (drag_helper->view->fullscreen) return false;
			if (drag_helper->view->role == wf::VIEW_ROLE_DESKTOP_ENVIRONMENT) return false;
			return true;
		}
		
		bool can_handle_drag() {
			return output->can_activate_plugin(grab_interface, wf::PLUGIN_ACTIVATE_ALLOW_MULTIPLE);
    }

		void floating_request(wayfire_view view) {
			wayfire_view grabbed_view = view;
			view = get_target_view(view);

			if (can_move_view(view)) {
				if (grab_input(view)) {
					 wf::move_drag::drag_options_t opts;
					 opts.enable_snap_off = view->fullscreen || view->tiled_edges;
					 opts.snap_off_threshold = 0;
					 opts.join_views = true;

					 grabbed_view->get_output()->focus_view(grabbed_view);
					 drag_helper->start_drag(view, get_global_input_coords(), opts);
					 slot.slot_id = wf::grid::SLOT_NONE;
				}
			}
		}

	public:
		void init() override {
			singleton_plugin_t::init();

			grab_interface->name = "genesis-shell";
			grab_interface->capabilities = wf::CAPABILITY_VIEW_DECORATOR | wf::CAPABILITY_GRAB_INPUT | wf::CAPABILITY_MANAGE_DESKTOP;
			
			grab_interface->callbacks.pointer.button = [=] (uint32_t b, uint32_t state) {
				if (state != WLR_BUTTON_RELEASED) return;
				if (b != BTN_LEFT) return;
				drag_helper->handle_input_released();
			};
			
			grab_interface->callbacks.pointer.motion = [=] (int x, int y) {
				(void)x;
				(void)y;
				
				drag_helper->handle_motion(get_global_input_coords());
				if (is_snap_enabled()) update_slot(calc_slot(get_input_coords()));
			};
			
			grab_interface->callbacks.touch.motion = [=] (int32_t id, int32_t x, int32_t y) {
				(void)id;
				(void)x;
				(void)y;

				drag_helper->handle_motion(get_global_input_coords());
				if (is_snap_enabled()) update_slot(calc_slot(get_input_coords()));
			};
			
			drag_helper->connect_signal("focus-output", &on_drag_output_focus);
      drag_helper->connect_signal("snap-off", &on_drag_snap_off);
      drag_helper->connect_signal("done", &on_drag_done);

			GError* error = NULL;
			shell = reinterpret_cast<GenesisShellShell*>(g_initable_new(GENESIS_SHELL_TYPE_SHELL, NULL, &error, NULL));
			if (shell == NULL || error != NULL) {
				LOGE("Failed to initialize Genesis Shell (", error->code, "): ", error->message);
				wf::get_core().shutdown();
			}

			for (auto output : wf::get_core().output_layout->get_outputs()) {
				create_monitor(output);
			}

			wf::get_core().connect_signal("keyboard-focus-changed", &focus_changed);
			wf::get_core().output_layout->connect_signal("output-added", &output_added);
			wf::get_core().output_layout->connect_signal("output-removed", &output_removed);

			genesis_common_shell_rescan_modules(GENESIS_COMMON_SHELL(shell), &error);
		}

		void fini() override {
			g_clear_object(&shell);
			singleton_plugin_t::fini();
		}
};

DECLARE_WAYFIRE_PLUGIN(wayfire_genesis_shell)