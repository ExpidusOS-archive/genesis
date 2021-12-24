namespace GenesisShell {
	public enum WindowRole {
		NONE = 0,
		TOPLEVEL,
		UNMANAGED,
		SHELL
	}

	[Flags]
	public enum WindowFlags {
		MAPPED,
		FOCUSABLE,
		DECORATABLE
	}

	[Flags]
	public enum WindowState {
		ACTIVE,
		STICKY,
		VISIBLE,
		MINIMIZED,
		MAXIMIZED,
		FULLSCREEN
	}

	[DBus(name = "com.expidus.genesis.Window")]
	public abstract class Window : GLib.Object {
		private Shell _shell;
		private string? _layout_name;
		private WindowLayout? _window_layout;
		private uint _obj_id;

		[DBus(visible = false)]
		public abstract Gdk.Rectangle geometry { get; }

		public abstract string monitor_name { get; }

		public virtual WindowRole role { get; }
		public virtual WindowFlags flags { get; }
		public virtual WindowState state { get; set; }

		public virtual string? application_id {
			get {
				return "";
			}
		}

		public virtual string? gtk_application_id {
			get {
				return "";
			}
		}
		
		public virtual string? dbus_app_menu_path {
			get {
				return "";
			}
		}
		
		public virtual string? dbus_menubar_path {
			get {
				return "";
			}
		}
		
		public virtual string? dbus_name {
			get {
				return "";
			}
		}

		public string? layout_name {
			get {
				var monitor = this.shell.find_monitor(this.monitor_name) as Monitor;
				if (monitor == null) return this._layout_name == null ? "" : this._layout_name;

				var layout = monitor.find_layout_provides(GenesisCommon.LayoutFlags.WINDOW_DECORATION);
				if (layout == null) return this._layout_name == null ? "" : this._layout_name;

				var is_null = this._layout_name == null;
				if (is_null || this._layout_name != layout.name) {
					this._layout_name = layout.name;

					if (!is_null) this._window_layout = null;
				}
				return this._layout_name == null ? "" : this._layout_name;
			}
		}

		[DBus(visible = false)]
		public WindowLayout? window_layout {
			get {
				var layout_name = this.layout_name;
				if (layout_name == null || layout_name == "") return this._window_layout;

				var layout = this.shell.get_layout_from_name(layout_name) as Layout;
				if (layout == null) return this._window_layout;

				if (this._window_layout == null) this._window_layout = layout.get_window_layout(this);
				return this._window_layout;
			}
		}

		[DBus(visible = false)]
		public Shell shell {
			get {
				return this._shell;
			}
			construct {
				this._shell = value;
			}
		}

		~Window() {
		}

		[DBus(visible = false)]
		public void destroy() {
			if (this._obj_id > 0) {
				this._shell.dbus_connection.unregister_object(this._obj_id);
				this._obj_id = 0;
			}
		}

		[DBus(name = "GetGeometry")]
		public void get_geometry_dbus(out int x, out int y, out int width, out int height) throws GLib.Error {
			x = this.geometry.x;
			y = this.geometry.y;
			width = this.geometry.width;
			height = this.geometry.height;
		}

		[DBus(visible = false)]
		public virtual bool init(Shell shell) throws GLib.Error {
			if (this._shell != null) return false;

			this._shell = shell;
			this._obj_id = this.shell.dbus_connection.register_object("/com/expidus/genesis/shell/window/%s".printf(this.to_string().down().replace("-", "").replace(" ", "")), this);
			return true;
		}

		[DBus(visible = false)]
		public virtual string to_string() {
			return "%p".printf(this);
		}

		[DBus(name = "ToString")]
		public string to_string_dbus() throws GLib.Error {
			return this.to_string();
		}
	}
}