namespace Genesis {
	public class GlobalMenu : GLib.MenuModel, GLib.ActionGroup {
		private GLib.MenuModel _default_menu;
		private GLib.ActionGroup _default_group;

		private GLib.MenuModel? _win_menu;
		private GLib.ActionGroup? _win_group;
		
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
			this._win_menu = null;
			this._win_group = null;

			if (disp.active_window != null) {
				this._win_menu = disp.active_window.menu;
				this._win_group = disp.active_window.action_group_app;
			}
		}

		public override GLib.Variant? get_item_attribute_value(int index, string attr, GLib.VariantType? type) {
			return this.active_menu.get_item_attribute_value(index, attr, type);
		}

		public override void get_item_attributes(int index, out GLib.HashTable<string, GLib.Variant>? attrs) {
			this.active_menu.get_item_attributes(index, out attrs);
		}

		public override GLib.MenuModel? get_item_link(int index, string lnk) {
			return this.active_menu.get_item_link(index, lnk);
		}

		public override void get_item_links(int index, out GLib.HashTable<string, GLib.MenuModel> links) {
			this.active_menu.get_item_links(index, out links);
		}

		public override int get_n_items() {
			return this.active_menu.get_n_items();
		}

		public override bool is_mutable() {
			return false;
		}

		public override GLib.MenuAttributeIter iterate_item_attributes(int index) {
			return this.active_menu.iterate_item_attributes(index);
		}

		public override GLib.MenuLinkIter iterate_item_links(int index) {
			return this.active_menu.iterate_item_links(index);
		}

		public void activate_action(string action_name, GLib.Variant? param) {
			this.active_group.activate_action(action_name, param);
		}

		public void change_action_state(string action_name, GLib.Variant value) {
			this.active_group.change_action_state(action_name, value);
		}

		public bool get_action_enabled(string action_name) {
			return this.active_group.get_action_enabled(action_name);
		}

		public unowned GLib.VariantType? get_action_parameter_type(string action_name) {
			return this.active_group.get_action_parameter_type(action_name);
		}

		public GLib.Variant? get_action_state(string action_name) {
			return this.active_group.get_action_state(action_name);
		}

		public GLib.Variant? get_action_state_hint(string action_name) {
			return this.active_group.get_action_state_hint(action_name);
		}

		public unowned GLib.VariantType? get_action_state_type(string action_name) {
			return this.active_group.get_action_state_type(action_name);
		}

		public bool has_action(string action_name) {
			return this.active_group.has_action(action_name);
		}

		public string[] list_actions() {
			return this.active_group.list_actions();
		}
	}
}