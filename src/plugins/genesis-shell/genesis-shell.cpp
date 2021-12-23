#include <wayfire/singleton-plugin.hpp>
#include <wayfire/plugin.hpp>
#include <wayfire/output.hpp>
#include <wayfire/output-layout.hpp>
#include <wayfire/workspace-manager.hpp>
#include <wayfire/signal-definitions.hpp>
#include <wayfire/util/log.hpp>
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

		wf::signal_connection_t view_attached = [=] (wf::signal_data_t* data) {
			auto signal_data = (wf::view_attached_signal*)data;

			create_window(signal_data->view);
		};

		wf::signal_connection_t view_detached = [=] (wf::signal_data_t* data) {
			auto signal_data = (wf::view_detached_signal*)data;

			genesis_shell_shell_remove_window(shell, signal_data->view->to_string().c_str());
		};

		wf::signal_connection_t view_updated = [=] (wf::signal_data_t* data) {
			GenesisShellWindow* win = genesis_shell_shell_find_window(shell, get_signaled_view(data)->to_string().c_str());
			if (win != NULL) update_window_decoration(win);
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

			for (auto output : wf::get_core().output_layout->get_outputs()) {
				for (auto view : output->workspace->get_views_in_layer(wf::ALL_LAYERS)) {
					auto win = genesis_shell_shell_find_window(shell, view->to_string().c_str());
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
									auto geo = view->get_output_geometry();

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
				win = genesis_shell_shell_find_window(shell, view->to_string().c_str());
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
								auto geo = view->get_output_geometry();

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

	public:
		void init() override {
			singleton_plugin_t::init();

			grab_interface->name = "genesis-shell";
			grab_interface->capabilities = wf::CAPABILITY_VIEW_DECORATOR | wf::CAPABILITY_GRAB_INPUT | wf::CAPABILITY_MANAGE_DESKTOP;

			GError* error = NULL;
			shell = reinterpret_cast<GenesisShellShell*>(g_initable_new(GENESIS_SHELL_TYPE_SHELL, NULL, &error, NULL));
			if (shell == NULL || error != NULL) {
				LOGE("Failed to initialize Genesis Shell (%d): %s", error->code, error->message);
				wf::get_core().shutdown();
			}

			for (auto output : wf::get_core().output_layout->get_outputs()) {
				create_monitor(output);
			}

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