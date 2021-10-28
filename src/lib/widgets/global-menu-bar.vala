namespace Genesis {
	public class GlobalMenuBar : Bin {
		private Gtk.PopoverMenuBar _menu_bar;
		private ulong _active_win_id;

		private GLib.MenuModel _default_menu;
		private GLib.ActionGroup _default_group;

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

			this._menu_bar = new Gtk.PopoverMenuBar.from_model(this._default_menu);
			this.child = this._menu_bar;
		}

		public override void map() {
			base.map();

			this._active_win_id = this.get_display().active_window_changed.connect(() => {
				this.sync();
			});

			this.sync();
		}

		public override void unmap() {
			this.get_display().disconnect(this._active_win_id);
			base.unmap();
		}

		private void sync() {
			if (this.get_mapped()) {
				var active_win = this.get_display().active_window;
				GLib.ActionGroup app_group = null;
				if (active_win != null && active_win.menu != null && active_win.action_group_app != null) {
					this._menu_bar.menu_model = active_win.menu;
					app_group = active_win.action_group_app;
				} else if (active_win != null && active_win.menu == null) {
					this._menu_bar.menu_model = new GLib.Menu();
					app_group = new GLib.SimpleActionGroup();
				} else {
					this._menu_bar.menu_model = this._default_menu;
					app_group = this._default_group;
				}
				//this._menu_bar.insert_action_group("app", app_group);
			}
		}
	}
}