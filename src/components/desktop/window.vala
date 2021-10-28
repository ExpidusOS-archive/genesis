namespace Genesis {
	public class Desktop : Window {
		construct {
			this.get_style_context().add_class("genesis-shell-desktop");

			this.type_hint = Genesis.WindowTypeHint.DESKTOP;
			this.decorated = false;
			this.skip_pager_hint = true;
			this.skip_taskbar_hint = true;
			this.resizable = false;
			this.monitor_size = true;
			this.show();

			this.get_style_context().remove_class("solid-csd");

			this.notify["content"].connect(() => {
				this.update_margins();
			});
		}

		public class Desktop(DesktopApplication application, string monitor_name) {
			Object(application: application, monitor_name: monitor_name);
		}

		public override void map() {
			base.map();

#if BUILD_X11
			var xsurf = this.get_window().backend as Gdk.X11.Surface;
			if (xsurf != null) xsurf.set_utf8_property("_NET_WM_NAME", "genesis-desktop");
#endif

			this.update_margins();
		}

		public void update_margins() {
		   if (this.content != null && this.monitor != null) {
				if (this.content is BaseWallpaper) {
					var children = this.content.observe_children();
					for (var i = 0; i < children.get_n_items(); i++) {
						var child = children.get_item(i) as Gtk.Widget;
						if (child == null) continue;

						var style_ctx = child.get_style_context();
						var margins = style_ctx.get_margin();

						child.margin_top = margins.top + this.monitor.workarea.y;
						child.margin_start = margins.left + this.monitor.workarea.x;

						child.margin_end = this.monitor.geometry.width - (margins.right + this.monitor.workarea.width + this.monitor.workarea.x);
						child.margin_bottom = this.monitor.geometry.height - (margins.bottom + this.monitor.workarea.height + this.monitor.workarea.y);
					}
				} else {
					var style_ctx = this.get_style_context();
					var margins = style_ctx.get_margin();

					this.content.margin_top = margins.top + this.monitor.workarea.y;
					this.content.margin_start = margins.left + this.monitor.workarea.x;

					this.content.margin_end = this.monitor.geometry.width - (margins.right + this.monitor.workarea.width + this.monitor.workarea.x);
					this.content.margin_bottom = this.monitor.geometry.height - (margins.bottom + this.monitor.workarea.height + this.monitor.workarea.y);
				}
			} else {
				this.margin_top = this.margin_bottom = this.margin_start = this.margin_end = 0;
			}
		}
	}
}