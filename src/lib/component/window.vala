namespace GenesisComponent {
  public class Window : GenesisCommon.Window { 
		private GenesisCommon.WindowClient _client;

		public string name {
			owned get;
      construct;
		}
    
    public override string monitor_name {
      owned get {
        return this._client.monitor_name;
      }
    }
    
    public override Gdk.Rectangle geometry {
      get {
        var rect = Gdk.Rectangle();
        try {
          this._client.get_geometry(out rect.x, out rect.y, out rect.width, out rect.height);
        } catch (GLib.Error e) {
          rect.x = rect.y = rect.height = rect.width = 0;
        }
        return rect;
      }
    }
    
		public override GenesisCommon.WindowRole role {
      get {
        return this._client.role;
      }
    }

		public override GenesisCommon.WindowFlags flags {
      get {
        return this._client.flags;
      }
    }

		public override GenesisCommon.WindowState state {
      get {
        return this._client.state;
      }
      set {
        this._client.state = value;
      }
    }

		public override string? application_id {
			owned get {
				return this._client.application_id;
			}
		}

		public override string? gtk_application_id {
			owned get {
				return this._client.gtk_application_id;
			}
		}
		
		public override string? dbus_app_menu_path {
			owned get {
				return this._client.dbus_app_menu_path;
			}
		}
		
		public override string? dbus_menubar_path {
			owned get {
				return this._client.dbus_menubar_path;
			}
		}
		
		public override string? dbus_win_path {
			owned get {
				return this._client.dbus_win_path;
			}
		}
		
		public override string? dbus_app_path {
			owned get {
				return this._client.dbus_app_path;
			}
		}
		
		public override string? dbus_name {
			owned get {
				return this._client.dbus_name;
			}
		}
    
    public Window(string name) {
      Object(name: name);
    }

		public override bool init(GenesisCommon.Shell shell) throws GLib.Error {
			if (base.init(shell)) {
				this._client = shell.dbus_connection.get_proxy_sync("com.expidus.genesis.Shell", "/com/expidus/genesis/shell/window/%s".printf(this.name.down().replace("-", "").replace(" ", "")));
        return true;
      }
      return false;
    }
		
		public override string to_string() {
			return this.name;
		}
  }
}