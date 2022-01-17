namespace ExpidusDesktop {
	public class WindowLayout : GenesisShell.WindowLayout {
		public override Gdk.Rectangle geometry {
			get {
				return { -5, -5, 20, 20 };
			}
		}
		
		public override GenesisCommon.LayoutWindowingMode windowing_mode {
			get {
				return GenesisCommon.LayoutWindowingMode.FLOATING;
			}
		}

		public WindowLayout(GenesisShell.Window win) {
			Object(window: win);
		}

		public override void draw(Cairo.Context cr) {
			GLib.message("We're rendering!");
		}
	}

	public class ShellLayout : GenesisShell.Layout {
		public override GenesisCommon.LayoutFlags flags {
			get {
				return GenesisCommon.LayoutFlags.WINDOW_DECORATION;
			}
		}

		public override string[] monitors {
			owned get {
				return this.shell.monitors;
			}
		}

		public override string name {
			get {
				return "desktop";
			}
		}

		public override bool try_last {
			get {
				return true;
			}
		}

		public override GenesisShell.WindowLayout? get_window_layout(GenesisShell.Window win) {
			return new WindowLayout(win);
		}
	}

	public class DesktopLayout : GenesisCommon.DesktopLayout {
		private GenesisWidgets.WallpaperSettings _wallpaper;

		public DesktopLayout(GenesisCommon.Shell shell, string monitor_name) {
			Object(shell: shell, monitor_name: monitor_name);
		}

		construct {
			this._wallpaper = new GenesisWidgets.WallpaperSettings();
			this._wallpaper.notify["image"].connect(() => this.queue_draw());
			this._wallpaper.notify["style"].connect(() => this.queue_draw());
		}

		public override void draw(Cairo.Context cr) {
			var geometry = this.monitor.geometry;
			cr.set_source_rgba(0.14, 0.15, 0.23, 1.0);
			cr.rectangle(0, 0, geometry.width, geometry.height);
			cr.fill();

			try {
				this._wallpaper.draw(cr, geometry.width, geometry.height);
			} catch (GLib.Error e) {}
		}
	}

	public class StatusPanelLayout : GenesisCommon.PanelLayout {
		private Gtk.Box _box;
		private Gtk.Box _box_right;
		private Gtk.Button _button_right;
		private GenesisWidgets.SimpleClock _clock;
		private GenesisWidgets.VolumePanelIcon _volume;
		private GenesisWidgets.NetworkPanelIcon _net;
		private GLib.Settings _settings;
		
		public override Gdk.Rectangle geometry {
			get {
				var geo = this.monitor.geometry;
				return { 0, 0, geo.width, this.monitor.dpi(25) };
			}
		}

		public override GenesisCommon.PanelAnchor anchor {
			get {
				return GenesisCommon.PanelAnchor.TOP;
			}
		}

		public StatusPanelLayout(GenesisCommon.Shell shell, string monitor_name) {
			Object(shell: shell, monitor_name: monitor_name);
			
			this._settings = new GLib.Settings("com.expidus.genesis.desktop");
			this._box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

			var btn = new Gtk.Button();
			btn.image = new Gtk.Image.from_icon_name("burst", Gtk.IconSize.LARGE_TOOLBAR);
			btn.set_relief(Gtk.ReliefStyle.NONE);
			
			{
				var style_ctx = btn.get_style_context();
				style_ctx.add_class("genesis-shell-applications-btn");
				style_ctx.add_class("genesis-shell-panel-applications-btn");
				style_ctx.remove_class("image-button");
			}
			
			btn.clicked.connect(() => {
				try {
					shell.toggle_ui(monitor_name, GenesisCommon.UIElement.APPS);
				} catch (GLib.Error e) {
					GLib.warning("Failed to call the application UI (%s:%d): %s", e.domain.to_string(), e.code, e.message);
				}
			});
			this._box.pack_start(btn, false, false, 0);
			
			this._button_right = new Gtk.Button();
			this._button_right.set_relief(Gtk.ReliefStyle.NONE);

			{
				var style_ctx = this._button_right.get_style_context();
				style_ctx.remove_class("image-button");
				style_ctx.add_class("genesis-shell-panel-item");
				style_ctx.add_class("genesis-shell-user-menu-btn");
			}
			
			this._button_right.clicked.connect(() => {
				try {
					shell.toggle_ui(monitor_name, GenesisCommon.UIElement.USER);
				} catch (GLib.Error e) {
					GLib.warning("Failed to call the user menu UI (%s:%d): %s", e.domain.to_string(), e.code, e.message);
				}
			});

			this._box_right = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			this._button_right.add(this._box_right);
			
			this._box.pack_end(this._button_right, false, false, 0);
			this.load_widgets.begin((obj, res) => this.load_widgets.end(res));
		}
		
		private async void load_widgets() {
			this._net = new GenesisWidgets.NetworkPanelIcon();

			{
				var style_ctx = this._net.get_style_context();
				style_ctx.add_class("genesis-shell-panel-network");
				style_ctx.add_class("genesis-shell-panel-item");
			}

			this._net.init_async.begin(GLib.Priority.DEFAULT, null, (obj, res) => {
				try {
					this._net.init_async.end(res);
				} catch (GLib.Error e) {}
			});
			this._box_right.pack_start(this._net, false, false, 0);

			this._volume = new GenesisWidgets.VolumePanelIcon();
			
			{
				var style_ctx = this._volume.get_style_context();
				style_ctx.add_class("genesis-shell-panel-volume");
				style_ctx.add_class("genesis-shell-panel-item");
			}

			this._volume.init_async.begin(GLib.Priority.DEFAULT, null, (obj, res) => {
				try {
					if (!this._volume.init_async.end(res)) {
						this._volume.hide();
					}
				} catch (GLib.Error e) {
					this._volume.hide();
				}
			});
			this._box_right.pack_start(this._volume, false, false, 0);

			this._clock = new GenesisWidgets.SimpleClock();
			{
				var style_ctx = this._clock.get_style_context();
				style_ctx.add_class("genesis-shell-panel-clock");
				style_ctx.add_class("genesis-shell-panel-item");
			}
			this._settings.bind("clock-format", this._clock, "format", GLib.SettingsBindFlags.GET);
			this._clock.format = this._settings.get_string("clock-format");
			this._box_right.pack_start(this._clock, false, false, 0);
		}
		
		public override void attach(Gtk.Container widget) {
			widget.add(this._box);
			this._box.show_all();
		}
		
		public override void detach(Gtk.Container widget) {
			widget.remove(this._box);
		}

		public override void draw(Cairo.Context cr) {
			var geometry = this.geometry;
			cr.set_source_rgba(0.14, 0.15, 0.23, 1.0);
			cr.rectangle(0, 0, geometry.width, geometry.height);
			cr.fill();
			
			this._box.draw(cr);
		}
	}

	public class PolkitDialog : GenesisCommon.PolkitDialog {
		public PolkitDialog(GenesisCommon.Monitor monitor, string action_id, string message, string icon_name, string cookie, GLib.Cancellable? cancellable) {
			Object(monitor: monitor, action_id: action_id, message: message, icon_name: icon_name, cookie: cookie, cancellable: cancellable);
		}
	}
	
	public class UILayout : GenesisCommon.UILayout {
		private Gtk.Window _win;

		public UILayout(GenesisCommon.Monitor monitor, GenesisCommon.UIElement el) {
			Object(monitor_name: monitor.name, ui_element: el);

			switch (el) {
				case GenesisCommon.UIElement.APPS:
					this._win = new ApplicationLauncher((GenesisComponent.Monitor)monitor);
					break;
				case GenesisCommon.UIElement.USER:
					this._win = new UserDashboard((GenesisComponent.Monitor)monitor);
					break;
				default:
					break;
			}

			if (this._win != null) this._win.show_all();
		}
		
		~UILayout() {
			if (this._win != null) {
				this._win.hide();
				this._win.unref();
				this._win = null;
			}
		}
	}

	public class ComponentLayout : GenesisCommon.Layout {
		public override GenesisCommon.LayoutFlags flags {
			get {
				return GenesisCommon.LayoutFlags.DESKTOP | GenesisCommon.LayoutFlags.PANEL | GenesisCommon.LayoutFlags.POLKIT_DIALOG | GenesisCommon.LayoutFlags.UI_ELEMENT;
			}
		}

		public override string[] monitors {
			owned get {
				return this.shell.monitors;
			}
		}

		public override string name {
			get {
				return "desktop";
			}
		}

		public override bool try_last {
			get {
				return true;
			}
		}

		public override GenesisCommon.DesktopLayout? get_desktop_layout(GenesisCommon.Monitor monitor) {
			return new DesktopLayout(monitor.shell, monitor.name);
		}

		public override GenesisCommon.PolkitDialog? get_polkit_dialog(GenesisCommon.Monitor monitor, string action_id, string message, string icon_name, string cookie, GLib.Cancellable? cancellable) {
			return new PolkitDialog(monitor, action_id, message, icon_name, cookie, cancellable);
		}

		public override GenesisCommon.PanelLayout? get_panel_layout(GenesisCommon.Monitor monitor, int i) {
			if (i == 0) return new StatusPanelLayout(monitor.shell, monitor.name);
			return null;
		}
		
		public override GenesisCommon.UILayout? get_ui_layout(GenesisCommon.Monitor monitor, GenesisCommon.UIElement el) {
			switch (el) {
				case GenesisCommon.UIElement.APPS:
				case GenesisCommon.UIElement.USER:
					return new UILayout(monitor, el);
				default:
					break;
			}
			return null;
		}

		public override int get_panel_count(GenesisCommon.Monitor monitor) {
			return 1;
		}
	}
}