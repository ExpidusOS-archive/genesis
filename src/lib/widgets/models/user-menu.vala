namespace Genesis {
	public class UserMenu : GLib.MenuModel, GLib.ActionGroup {
		private GLib.Menu _menu;
		private GLib.SimpleActionGroup _group;

		construct {
			this._menu = new GLib.Menu();
			{
				var item = new GLib.MenuItem("Log Out", "user.log-out");
				item.set_action_and_target("user.log-out", null);
				this._menu.append_item(item);
			}

			this._group = new GLib.SimpleActionGroup();
			{
				var action = new GLib.SimpleAction("log-out", null);
				action.activate.connect(() => {
					try {
						var shell = GLib.Bus.get_proxy_sync<ShellClient>(GLib.BusType.SESSION, "com.expidus.GenesisShell", "/com/expidus/GenesisShell");
						shell.shutdown();
					} catch (GLib.Error e) {
						// TODO: alternative method(s)
					}
				});
				this._group.add_action(action);
			}
		}

		public override GLib.Variant? get_item_attribute_value(int index, string attr, GLib.VariantType? type) {
			return this._menu.get_item_attribute_value(index, attr, type);
		}

		public override void get_item_attributes(int index, out GLib.HashTable<string, GLib.Variant>? attrs) {
			this._menu.get_item_attributes(index, out attrs);
		}

		public override GLib.MenuModel? get_item_link(int index, string lnk) {
			return this._menu.get_item_link(index, lnk);
		}

		public override void get_item_links(int index, out GLib.HashTable<string, GLib.MenuModel> links) {
			this._menu.get_item_links(index, out links);
		}

		public override int get_n_items() {
			return this._menu.get_n_items();
		}

		public override bool is_mutable() {
			return false;
		}

		public override GLib.MenuAttributeIter iterate_item_attributes(int index) {
			return this._menu.iterate_item_attributes(index);
		}

		public override GLib.MenuLinkIter iterate_item_links(int index) {
			return this._menu.iterate_item_links(index);
		}

		public void activate_action(string action_name, GLib.Variant? param) {
			this._group.activate_action(action_name, param);
		}

		public void change_action_state(string action_name, GLib.Variant value) {
			this._group.change_action_state(action_name, value);
		}

		public bool get_action_enabled(string action_name) {
			return this._group.get_action_enabled(action_name);
		}

		public unowned GLib.VariantType? get_action_parameter_type(string action_name) {
			return this._group.get_action_parameter_type(action_name);
		}

		public GLib.Variant? get_action_state(string action_name) {
			return this._group.get_action_state(action_name);
		}

		public GLib.Variant? get_action_state_hint(string action_name) {
			return this._group.get_action_state_hint(action_name);
		}

		public unowned GLib.VariantType? get_action_state_type(string action_name) {
			return this._group.get_action_state_type(action_name);
		}

		public bool has_action(string action_name) {
			return this._group.has_action(action_name);
		}

		public string[] list_actions() {
			return this._group.list_actions();
		}
	}
}