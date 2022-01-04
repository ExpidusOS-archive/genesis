namespace GenesisWidgets {
  public struct MenuImpl {
    public GLib.ActionGroup win_action_group;
    public GLib.ActionGroup app_action_group;
    public GLib.MenuModel menu;

    public MenuImpl(GLib.ActionGroup app_group, GLib.ActionGroup win_group, GLib.MenuModel menu) {
      this.win_action_group = win_group;
      this.app_action_group = app_group;
      this.menu = menu;
    }
  }

  public class GlobalMenu : Gtk.MenuBar {
    private ulong _window_update_id;
    
    public GLib.MenuModel menu_model {
      owned get {
        return this.get_current().menu;
      }
    }

		public GenesisCommon.Shell shell {
			get;
			set construct;
		}
    
    public GlobalMenu(GenesisCommon.Shell shell) {
      Object(shell: shell);
    }

    construct {
      this._window_update_id = this.shell.window_changed.connect(() => this.update());
      this.update();
    }
    
    ~GlobalMenu() {
      if (this._window_update_id > 0) {
        this.shell.disconnect(this._window_update_id);
        this._window_update_id = 0;
      }
    }

    public virtual MenuImpl get_default() {
      return {};
    }
    
    private MenuImpl get_current() {
      var win = this.shell.find_active_window();
      if (win != null) {
        if (win.dbus_name != null && win.dbus_menubar_path != null && win.dbus_name.length > 0 && win.dbus_menubar_path.length > 0) {
          GLib.debug("Using window %s for global menu", win.to_string());
          var app_action_group = GLib.DBusActionGroup.@get(this.shell.dbus_connection, win.dbus_name, win.dbus_app_path);
          var win_action_group = GLib.DBusActionGroup.@get(this.shell.dbus_connection, win.dbus_name, win.dbus_win_path);
          var menu = GLib.DBusMenuModel.@get(this.shell.dbus_connection, win.dbus_name, win.dbus_menubar_path);
          return MenuImpl(app_action_group, win_action_group, menu);
        }
      }

      GLib.debug("Using default for global menu");
      return this.get_default();
    }
    
    private void update() {
      var impl = this.get_current();
      this.insert_action_group("app", impl.app_action_group);
      this.insert_action_group("win", impl.win_action_group);
      this.bind_model(impl.menu, null, false);
      
      this.show_all();
    }
  }
}