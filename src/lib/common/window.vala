namespace GenesisCommon {
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

	/**
		* Base class for windows
		*/
	[DBus(name = "com.expidus.genesis.Window")]
  public abstract class Window : GLib.Object {
    [DBus(visible = false)]
    public Shell shell { get; }

		[DBus(visible = false)]
		public abstract Gdk.Rectangle geometry { get; }

		public abstract string monitor_name { owned get; }

		public virtual WindowRole role { get; }
		public virtual WindowFlags flags { get; }
		public virtual WindowState state { get; set; }

		public virtual string? application_id {
			owned get {
				return "";
			}
		}

		public virtual string? gtk_application_id {
			owned get {
				return "";
			}
		}
		
		public virtual string? dbus_app_menu_path {
			owned get {
				return "";
			}
		}
		
		public virtual string? dbus_menubar_path {
			owned get {
				return "";
			}
		}
		
		public virtual string? dbus_win_path {
			owned get {
				return "";
			}
		}
		
		public virtual string? dbus_app_path {
			owned get {
				return "";
			}
		}
		
		public virtual string? dbus_name {
			owned get {
				return "";
			}
		}

		/**
			* Similar to ''GLib.Initable.init''
			*
			* This function works similar to ''GLib.Initable.init'' except it takes in a shell instance. ''Never call this method directly.''
			*
			* @param shell The shell instance to use for the monitor
			* @throws GLib.Error The error that occurred while initializing.
			* @return True if initialized correctly, false if not
			*/
		[DBus(visible = false)]
		public virtual bool init(Shell shell) throws GLib.Error {
			if (this._shell != null) return false;

			this._shell = shell;
			return true;
		}

		[DBus(name = "GetGeometry")]
		public void get_geometry_dbus(out int x, out int y, out int width, out int height) throws GLib.Error { 
			x = this.geometry.x;
			y = this.geometry.y;
			width = this.geometry.width;
			height = this.geometry.height;
    }
  }
  
	[DBus(name = "com.expidus.genesis.Window")]
  public interface WindowClient : GLib.Object {
		public abstract string monitor_name { owned get; }

		public abstract WindowRole role { get; }
		public abstract WindowFlags flags { get; }
		public abstract WindowState state { get; set; }

		public abstract string? application_id { owned get; }
		public abstract string? gtk_application_id { owned get; }
		public abstract string? dbus_app_menu_path { owned get; }
		public abstract string? dbus_menubar_path { owned get; }
		public abstract string? dbus_win_path { owned get; }
		public abstract string? dbus_app_path { owned get; }
		public abstract string? dbus_name { owned get; }

		public abstract void get_geometry(out int x, out int y, out int width, out int height) throws GLib.Error;
  }
}