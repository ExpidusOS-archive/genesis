namespace Genesis {
	public class UserButton : Bin {
		private UserIcon _icon;
		private UserMenu _menu;
		private Gtk.MenuButton _btn;

		construct {
			this._icon = new UserIcon();

			this._menu = new UserMenu();

			this._btn = new Gtk.MenuButton();
			this._btn.menu_model = this._menu;

			var toggle_btn = this._btn.get_first_child() as Gtk.ToggleButton;
			assert(toggle_btn != null);
			toggle_btn.child = this._icon;

			this._btn.insert_action_group("user", this._menu);

			this.child = this._btn;
		}
	}
}