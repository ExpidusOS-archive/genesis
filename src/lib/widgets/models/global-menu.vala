namespace Genesis {
	public class GlobalMenu : GLib.Object {
		private GLib.MenuModel _default_menu;
		private GLib.ActionGroup _default_group;

		private GLib.MenuModel? _win_menu;
		private GLib.ActionGroup? _win_group;

		private bool _should_update;
		
		public GLib.MenuModel active_menu {
			get {
				if (this._win_menu != null) return this._win_menu;
				return this._default_menu;
			}
		}
		
		public GLib.ActionGroup active_group {
			get {
				if (this._win_group != null) return this._win_group;
				return this._default_group;
			}
		}
		
		public GLib.ActionGroup default_group {
			get {
				return this._default_group;
			}
		}

		public bool should_update {
			get {
				return this._should_update;
			}
			set {
				this._should_update = value;
			}
		}

		construct {
			if (this._default_menu == null || this._default_group == null) {
				try {
					var conn = GLib.Bus.get_sync(GLib.BusType.SESSION);
					this._default_menu = GLib.DBusMenuModel.@get(conn, "com.expidus.GenesisDesktop", "/com/expidus/GenesisDesktop/menus/menubar");
					this._default_group = GLib.DBusActionGroup.@get(conn, "com.expidus.GenesisDesktop", "/com/expidus/GenesisDesktop");
				} catch (GLib.Error e) {
					GLib.error("%s (%d): %s", e.domain.to_string(), e.code, e.message);
					this._default_menu = new GLib.Menu();
					this._default_group = new GLib.SimpleActionGroup();
				}
			}
		}

		public void sync(Display disp) {
			var menu_old = this.active_menu;
			var group_old = this.active_group;

			if (disp.active_window != null) {
				this._win_menu = disp.active_window.menu;
				this._win_group = disp.active_window.action_group_app;
			} else {
				this._win_menu = null;
				this._win_group = null;
			}

			if (this.active_menu != menu_old || this.active_group != group_old) {
				this.notify_property("active-menu");
				this.notify_property("active-group");
			}
		}
	}
}