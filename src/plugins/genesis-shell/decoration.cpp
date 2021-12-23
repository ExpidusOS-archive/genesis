#include <wayfire/decorator.hpp>
#include <wayfire/compositor-surface.hpp>
#include <wayfire/opengl.hpp>
#include <wayfire/signal-definitions.hpp>
#include <wayfire/surface.hpp>
#include <wayfire/view.hpp>
#include <wayfire/plugins/common/cairo-util.hpp>
#include <wayfire/util/log.hpp>
#include "decoration.hpp"

class genesis_shell_decoration_surface : public wf::surface_interface_t, public wf::compositor_surface_t, public wf::decorator_frame_t_t {
	private:
		bool _mapped = true;
		GenesisShellWindow* win;
		wf::region_t cached_region;

		wf::signal_connection_t on_subsurface_removed = [&] (auto data) {
			auto ev = static_cast<wf::subsurface_removed_signal*>(data);
			if (ev->subsurface.get() == this) {
				unmap();
			}
		};
	public:
		genesis_shell_decoration_surface(GenesisShellWindow* win) {
			this->win = win;
			this->cached_region = {};

			auto view = genesis_shell_wayfire_window_get_wayfire_view(win);
			view->connect_signal("subsurface-removed", &on_subsurface_removed);
			view->damage();
		}

		virtual bool is_mapped() const final {
			return _mapped;
		}
		
		void unmap() {
			_mapped = false;
			wf::emit_map_state_change(this);
		}

		wf::point_t get_offset() final {
			GenesisShellWindowLayout* window_layout = NULL;
			g_object_get(win, "window-layout", &window_layout, NULL);

			if (window_layout != NULL) {
				GdkRectangle rect = { 0, 0, 0, 0 };
				g_object_get(window_layout, "geometry", &rect, NULL);
				return { -rect.x, -rect.y };
			}

			return { 0, 0 };
		}

		virtual wf::dimensions_t get_size() const final {
			GenesisShellWindowLayout* window_layout = NULL;
			g_object_get(win, "window-layout", &window_layout, NULL);

			if (window_layout != NULL) {
				GdkRectangle rect = { 0, 0, 0, 0 };
				g_object_get(window_layout, "geometry", &rect, NULL);
				return { rect.width, rect.height };
			}

			return { 0, 0 };
		}

		virtual void simple_render(const wf::framebuffer_t& fb, int x, int y, const wf::region_t& damage) override {
			wf::region_t frame = this->cached_region + wf::point_t{x, y};
      frame &= damage;

			LOGD("Beginning rendering of decoration");

			GenesisShellWindowLayout* window_layout = NULL;
			GdkRectangle geo = { 0, 0, 0, 0 };
			g_object_get(win, "window-layout", &window_layout, "geometry", &geo, NULL);

			if (window_layout == NULL) {
				LOGW("Window layout was not set for window");
				return;
			}

			cairo_surface_t* img_surf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, geo.width, geo.height);
			cairo_t* cr = cairo_create(img_surf);
			genesis_common_basic_layout_draw(GENESIS_COMMON_BASIC_LAYOUT(window_layout), cr);
			cairo_destroy(cr);

			OpenGL::render_begin(fb);
			for (const auto& pixbox : frame) {
				wlr_box box = wlr_box_from_pixman_box(pixbox);
				fb.logic_scissor(box);
				wf::geometry_t geo = { box.x + x, box.y + y, box.width, box.height };

				cairo_surface_t* region_surf = cairo_surface_create_for_rectangle(img_surf, box.x, box.y, box.width, box.height);
				wf::simple_texture_t tex;
				cairo_surface_upload_to_texture(region_surf, tex);
				cairo_surface_destroy(region_surf);

				OpenGL::render_texture(tex.tex, fb, geo, glm::vec4(1.0f), OpenGL::TEXTURE_TRANSFORM_INVERT_Y);
			}
			OpenGL::render_end();
			cairo_surface_destroy(img_surf);

			LOGD("End rendering of decoration");
		}

		virtual wf::geometry_t expand_wm_geometry(wf::geometry_t contained_wm_geometry) override {
			GenesisShellWindowLayout* window_layout = NULL;
			g_object_get(win, "window-layout", &window_layout, NULL);

			if (window_layout != NULL) {
				GdkRectangle rect = { 0, 0, 0, 0 };
				g_object_get(window_layout, "geometry", &rect, NULL);

				contained_wm_geometry.x -= rect.x;
				contained_wm_geometry.y -= rect.y;
				contained_wm_geometry.width += rect.width;
				contained_wm_geometry.height += rect.height;
			}
			return contained_wm_geometry;
		}

		virtual void calculate_resize_size(int& target_width, int& target_height) override {
			GenesisShellWindowLayout* window_layout = NULL;
			g_object_get(win, "window-layout", &window_layout, NULL);

			if (window_layout != NULL) {
				GdkRectangle rect = { 0, 0, 0, 0 };
				g_object_get(window_layout, "geometry", &rect, NULL);

				target_width -= rect.width;
				target_height -= rect.height;

				target_width = std::max(target_width, 1);
				target_height = std::max(target_height, 1);
			}
		}

		virtual void notify_view_resized(wf::geometry_t view_geometry) override {
			auto view = genesis_shell_wayfire_window_get_wayfire_view(win);
			view->damage();

			if (!view->fullscreen) {
				this->cached_region = {};
				this->cached_region &= view_geometry;
			}

			view->damage();
		}
};

void genesis_shell_wayfire_window_init_view(GenesisShellWindow* self) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(self);
	auto surf = std::make_unique<genesis_shell_decoration_surface>(self);
	auto ptr = surf.get();

	view->add_subsurface(std::move(surf), true);
	view->set_decoration(ptr);
	view->damage();
	LOGD("Created decoration ", ptr, " for view \"", view->to_string());
}

void genesis_shell_wayfire_window_deinit_view(GenesisShellWindow* self) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(self);
	auto decor = dynamic_cast<genesis_shell_decoration_surface*>(view->get_decoration().get());
	if (!decor) return;
	decor->unmap();
	view->set_decoration(nullptr);
}