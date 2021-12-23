namespace GenesisShell {
	public class Desktop : GenesisWidgets.LayerWindow {
		private GenesisCommon.DesktopLayout _desktop_layout;
		private string? _layout_name;
		private string? _layout_name_panel;
		private GLib.List<Panel> _panels;

		public string? layout_name {
			get {
				var application = (GenesisWidgets.Application)this.application;

				var monitor = application.shell.find_monitor(this.monitor_name) as GenesisComponent.Monitor;
				if (monitor == null) return this._layout_name;

				var layout = monitor.find_layout_provides(GenesisCommon.LayoutFlags.DESKTOP);
				if (layout == null) return this._layout_name;

				var is_null = this._layout_name == null;
				if (is_null || this._layout_name != layout.name) {
					this._layout_name = layout.name;

					if (!is_null) {
						this._desktop_layout.detach(this);
						this._desktop_layout = null;
					}
				}
				return this._layout_name;
			}
		}

		public string? layout_name_panel {
			get {
				var application = (GenesisWidgets.Application)this.application;

				var monitor = application.shell.find_monitor(this.monitor_name) as GenesisComponent.Monitor;
				if (monitor == null) return this._layout_name_panel;

				var layout = monitor.find_layout_provides(GenesisCommon.LayoutFlags.PANEL);
				if (layout == null) return this._layout_name_panel;

				this._panels.foreach((e) => this._panels.remove(e));
				this._layout_name_panel = layout.name;

				for (var i = 0; i < layout.get_panel_count(monitor); i++) {
					var layout_panel = layout.get_panel_layout(monitor, i);
					if (layout_panel == null) continue;

					this._panels.append(new Panel(layout_panel));
				}
				return this._layout_name_panel;
			}
		}

		public GenesisCommon.DesktopLayout? desktop_layout {
			get {
				var layout_name = this.layout_name;
				if (layout_name == null) return this._desktop_layout;

				var application = (GenesisWidgets.Application)this.application;
				var layout = application.shell.get_layout_from_name(layout_name);
				if (layout == null) return this._desktop_layout;

				if (this._desktop_layout == null) {
					this._desktop_layout = layout.get_desktop_layout(application.shell.find_monitor(this.monitor_name));
					this._desktop_layout.queue_draw.connect(() => {
						this.queue_draw();
					});
					this._desktop_layout.attach(this);
				}
				return this._desktop_layout;
			}
		}

		construct {
			this.type_hint = Gdk.WindowTypeHint.DESKTOP;
			this.get_style_context().add_class("genesis-shell-desktop");
		}

		public Desktop(GenesisWidgets.Application application, string monitor_name) {
			Object(application: application, monitor_name: monitor_name, layer: GtkLayerShell.Layer.BACKGROUND);

			var monitor = application.shell.find_monitor(monitor_name);
			monitor.layout_detached.connect((name) => {
				if (name == this._layout_name || name == this._layout_name_panel) {
					this.notify_property("layout_name");
					this.notify_property("layout_name_panel");
					this.notify_property("desktop_layout");
					this.queue_draw();
				}
			});
			
			this._panels = new GLib.List<Panel>();

			var layout = monitor.find_layout_provides(GenesisCommon.LayoutFlags.PANEL);
			if (layout != null) {
				this._layout_name_panel = layout.name;

				for (var i = 0; i < layout.get_panel_count(monitor); i++) {
					var layout_panel = layout.get_panel_layout(monitor, i);
					if (layout_panel == null) continue;

					this._panels.append(new Panel(layout_panel));
				}
			}

			this.show_all();
		}

		public override void get_preferred_width(out int min_width, out int nat_width) {
			min_width = nat_width = this.monitor.geometry.width;
		}

		public override void get_preferred_height(out int min_height, out int nat_height) {
			min_height = nat_height = this.monitor.geometry.height;
		}

		public override bool draw(Cairo.Context cr) {
			base.draw(cr);

			var layout = this.desktop_layout;
			if (layout == null) return false;

			layout.draw(cr);
			return true;
		}
	}
}