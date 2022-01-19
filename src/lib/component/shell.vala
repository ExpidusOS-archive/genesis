namespace GenesisComponent {
	private struct ModuleState {
		public Peas.PluginInfo info;
	}

	[DBus(name = "com.expidus.genesis.ComponentShell")]
	public class Shell : GenesisCommon.Shell, GLib.Initable {
		private GenesisCommon.ShellClient _client;
		private Peas.Engine _engine;
		private Peas.ExtensionSet _extensions;
		private GLib.DBusConnection? _dbus_conn;
		private GLib.HashTable<string, ModuleState?> _plugins;
		private GLib.HashTable<string, Monitor> _monitors;
		private GLib.HashTable<string, GenesisCommon.Layout> _module_layouts;
		private GLib.HashTable<string, Window> _windows;
		private GLib.HashTable<string, GenesisCommon.UILayout> _ui_layouts;
		private string _active_window;
		private uint _obj_id;

		public override string[] modules {
			owned get {
				if (this._client == null) return {};
				return this._client.modules;
			}
		}

		public override string[] monitors {
			owned get {
				if (this._client == null) return {};
				return this._client.monitors;
			}
		}

		public override string[] layouts {
			owned get {
				if (this._client == null) return {};
				return this._client.layouts;
			}
		}

		public override string[] windows {
			owned get {
				if (this._client == null) return {};
				return this._client.windows;
			}
		}

		public override string active_window {
			owned get {
				if (this._active_window == null) return this._client.active_window;
				return this._active_window;
			}
		}

		public override GenesisCommon.ShellInstanceType instance_type {
			get {
				return GenesisCommon.ShellInstanceType.COMPONENT;
			}
		}

		[DBus(visible = false)]
		public override GLib.DBusConnection? dbus_connection {
			get {
				return this._dbus_conn;
			}
			construct {
				this._dbus_conn = value;
			}
		}

		construct {
			this._plugins = new GLib.HashTable<string, ModuleState?>(GLib.str_hash, GLib.str_equal);
			this._monitors = new GLib.HashTable<string, Monitor>(GLib.str_hash, GLib.str_equal);
			this._module_layouts = new GLib.HashTable<string, GenesisCommon.Layout>(GLib.str_hash, GLib.str_equal);
			this._windows = new GLib.HashTable<string, Window>(GLib.str_hash, GLib.str_equal);
			this._ui_layouts = new GLib.HashTable<string, GenesisCommon.UILayout>(GLib.str_hash, GLib.str_equal);

			this._engine = new Peas.Engine();
			this._engine.enable_loader("lua5.1");
			this._engine.enable_loader("python3");
			this._engine.add_search_path(GenesisCommon.LIBDIR + "/genesis/modules/", GenesisCommon.DATADIR + "/genesis/modules/");

			this._extensions = new Peas.ExtensionSet(this._engine, typeof (GenesisComponent.Module), "object", this);
			this._extensions.extension_added.connect((info, obj) => {
				if (!this._plugins.contains(info.get_module_name()) && info.get_module_name() in this.modules) {
					var module = (Module)obj;
					ModuleState state = { info };

					this._plugins.insert(info.get_module_name(), state);
					GLib.debug("Registered module \"%s\"", info.get_module_name());

					var activatable = obj as Peas.Activatable;
					if (activatable != null) activatable.activate();
					this.module_added(info.get_module_name());
				}
			});

			this._extensions.extension_removed.connect((info, obj) => {
				if (this._plugins.contains(info.get_module_name())) {
					var module = (Module)obj;
					var activatable = obj as Peas.Activatable;
					if (activatable != null) activatable.deactivate();

					if (this._module_layouts.contains(info.get_module_name())) {
						var layout = this._module_layouts.get(info.get_module_name());

						try {
							this.remove_layout(module, layout);
						} catch (GLib.Error e) {
							GLib.error("Failed to remove and detach layout \"%s\" from module \"%s\" (%s:%d): %s", layout.name, info.get_module_name(), e.domain.to_string(), e.code, e.message);
						}
					}

					this._plugins.remove(info.get_module_name());
					this.module_removed(info.get_module_name());
					GLib.debug("Unregistered module \"%s\"", info.get_module_name());
				}
			});
		}

		public Shell(Gtk.Application? application = null) {
			Object(application: application);
		}

		public Shell.with_dbus_connection(GLib.DBusConnection dbus_connection, Gtk.Application? application = null) {
			Object(dbus_connection: dbus_connection, application: application);
		}
		
		public override bool is_showing_ui(string monitor_name, GenesisCommon.UIElement el) throws GLib.Error {
			if (this._ui_layouts.contains(monitor_name)) return this._ui_layouts.get(monitor_name).ui_element == el;
			return false;
		}

		public override bool show_ui(string monitor_name, GenesisCommon.UIElement el) throws GLib.Error {
			bool should_create = true;
			if (this._ui_layouts.contains(monitor_name)) should_create = this._ui_layouts.get(monitor_name).ui_element != el;
			
			if (should_create) {
				var monitor = (Monitor)this.find_monitor(monitor_name);
				if (monitor != null) {
					var layout = monitor.find_layout_provides(GenesisCommon.LayoutFlags.UI_ELEMENT);
					if (layout != null) {
						var ui = layout.get_ui_layout(monitor, el);
						if (ui != null) {
							this._ui_layouts.set(monitor_name, (owned)ui);
							this.ui_element_shown(monitor_name, el);
							return true;
						}
					}
				}
			}

			var r = this._client.show_ui(monitor_name, el);
			this.ui_element_shown(monitor_name, el);
			return r;
		}

		public override bool close_ui(string monitor_name, GenesisCommon.UIElement el) throws GLib.Error {
			if (this._ui_layouts.contains(monitor_name)) {
				this._ui_layouts.remove(monitor_name);
				return true;
			}
			return false;
		}

		[DBus(visible = false)]
		public override GenesisCommon.Layout? get_layout_from_name(string name) {
			foreach (var value in this._module_layouts.get_values()) {
				if (value.name == name) {
					return value;
				}
			}
			return null;
		}

		[DBus(visible = false)]
		public override GenesisCommon.Module? get_module_for_layout(GenesisCommon.Layout layout) {
			foreach (var key in this._module_layouts.get_keys()) {
				var found = this._module_layouts.get(key);

				if (found.name == layout.name) {
					return this.get_module(key);
				}
			}
			return null;
		}
		
		[DBus(visible = false)]
		public override unowned GenesisCommon.Window? find_window(string key) {
			if (!this._windows.contains(key)) {
				try {
					var win = new Window(key);
					win.init(this);
					this._windows.insert(key, (owned)win);
				} catch (GLib.Error e) {
					GLib.warning("Failed to add window %s (%s): %s", key, e.domain.to_string(), e.message);
				}
			}
			return this._windows.get(key);
		}

		[DBus(visible = false)]
		public override unowned GenesisCommon.Monitor? find_monitor(string name) {
			return this._monitors.get(name);
		}

		public override void rescan_modules() throws GLib.Error {
			GLib.debug("Loading modules from " + GenesisCommon.LIBDIR + "/genesis/modules/");
			this._engine.rescan_plugins();
		}

		public override bool load_module(string name) throws GLib.Error {
			if (!(name in this.modules)) throw new GenesisCommon.ShellError.INVALID_MODULE("Module was not requested by shell");

			if (!this._plugins.contains(name)) {
				foreach (var info in this._engine.get_plugin_list()) {
					if (info.get_module_name() == name) {
						return this._engine.try_load_plugin(info);
					}
				}
			}
			return false;
		}

		public override bool unload_module(string name) throws GLib.Error {
			if (this._plugins.contains(name)) {
				foreach (var info in this._engine.get_plugin_list()) {
					if (info.get_module_name() == name) {
						return this._engine.try_unload_plugin(info);
					}
				}
			}
			return false;
		}

		[DBus(visible = false)]
		public Module? get_module(string name) {
			if (this._plugins.contains(name)) {
				return this._extensions.get_extension(this._plugins.get(name).info) as Module;
			}
			return null;
		}

		[DBus(visible = false)]
		public override Peas.PluginInfo? get_info_for_module(GenesisCommon.Module module) {
			string? name;
			if (this.check_module(module, out name)) {
				return this._plugins.get(name).info;
			}
			return null;
		}

		[DBus(visible = false)]
		public override bool check_module(GenesisCommon.Module module, out string? nm) {
			nm = null;
			foreach (var name in this.modules) {
				var m = this.get_module(name);
				if (m == null) continue;

				if (module == m) {
					nm = name;
					return true;
				}
			}
			return false;
		}

		[DBus(visible = false)]
		public override void define_layout(GenesisCommon.Module _module, GenesisCommon.Layout layout) throws GenesisCommon.ShellError {
			var module = _module as Module;
			if (module == null) throw new GenesisCommon.ShellError.INVALID_MODULE("Module is not a shell type module");

			string? name;
			if (!this.check_module(module, out name)) throw new GenesisCommon.ShellError.INVALID_MODULE("Module authenticity cannot be verified");
			if (this._module_layouts.contains(name)) throw new GenesisCommon.ShellError.INVALID_MODULE("Module already registered a layout");

			foreach (var value in this._module_layouts.get_values()) {
				if (value.name == layout.name) throw new GenesisCommon.ShellError.INVALID_LAYOUT("Layout is already provided by a module");
			}

			layout.init(this);
			this._module_layouts.set(name, layout);

			GLib.debug("Registered layout \"%s\" provided by \"%s\"", layout.name, name);

			this.layout_added(layout.name);
		}

		[DBus(visible = false)]
		public override void remove_layout(GenesisCommon.Module module, GenesisCommon.Layout layout) throws GenesisCommon.ShellError {
			string? name;
			if (!this.check_module(module, out name)) throw new GenesisCommon.ShellError.INVALID_MODULE("Module authenticity cannot be verified");
			if (!this._module_layouts.contains(name)) throw new GenesisCommon.ShellError.INVALID_MODULE("Module did not register layout");
			if (this._module_layouts.get(name).name != layout.name) throw new GenesisCommon.ShellError.INVALID_LAYOUT("Registered layout and provided layout do not match");

			this._module_layouts.remove(name);
			this.layout_removed(layout.name);
		}

		public override bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
			if (!base.init(cancellable)) return false;

			if (this._dbus_conn == null) {
				GLib.debug("No DBus connection was given, creating our own connection");
				this._dbus_conn = GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable);
			}

			this._obj_id = this._dbus_conn.register_object("/com/expidus/genesis/component", (GenesisCommon.Shell)this);
			this._client = this._dbus_conn.get_proxy_sync("com.expidus.genesis.Shell", "/com/expidus/genesis/shell");
			this._client.module_added.connect((module_name) => {
				try {
					this.load_module(module_name);
				} catch (GLib.Error e) {
					GLib.error("Failed to load module %s (%s:%d): %s", module_name, e.domain.to_string(), e.code, e.message);
				}
			});

			this._client.module_removed.connect((module_name) => {
				try {
					this.unload_module(module_name);
				} catch (GLib.Error e) {
					GLib.error("Failed to unload module %s (%s:%d): %s", module_name, e.domain.to_string(), e.code, e.message);
				}
			});

			this._client.monitor_added.connect((monitor_name) => {
				try {
					this.load_monitor(monitor_name);
				} catch (GLib.Error e) {
					GLib.error("Failed to load module %s (%s:%d): %s", monitor_name, e.domain.to_string(), e.code, e.message);
				}
			});

			this._client.monitor_removed.connect((monitor_name) => {
				if (this._monitors.contains(monitor_name)) {
					this._monitors.remove(monitor_name);
					this.monitor_removed(monitor_name);
				}
			});

			this._client.layout_removed.connect((layout_name) => {
				var layout = this.get_layout_from_name(layout_name);
				if (layout == null) return;

				var module = this.get_module_for_layout(layout);
				if (module == null) return;

				try {
					this.remove_layout(module, layout);
				} catch (GLib.Error e) {
					GLib.error("Failed to removee layout %s (%s:%d): %s", layout_name, e.domain.to_string(), e.code, e.message);
				}
			});
			
			this._client.window_added.connect((name) => {
				var win = new Window(name);
				try {
					win.init(this);
					this._windows.insert(name, (owned)win);
					this.window_added(name);
				} catch (GLib.Error e) {
					GLib.warning("Failed to add window %s (%s): %s", name, e.domain.to_string(), e.message);
				}
			});

			this._client.window_removed.connect((name) => {
				this._windows.remove(name);
				this.window_removed(name);
			});
			
			this._client.window_changed.connect((name) => {
				this._active_window = name;
				this.window_changed(name);
			});
			
			this._client.ui_element_shown.connect((monitor_name, el) => {
				try {
					this.show_ui(monitor_name, el);
				} catch (GLib.Error e) {}
			});

			foreach (var monitor_name in this.monitors) this.load_monitor(monitor_name);
			foreach (var module_name in this.modules) this.load_module(module_name);
			return true;
		}

		[DBus(visible = false)]
		private void load_monitor(string name) throws GLib.Error {
			if (!this._monitors.contains(name)) {
				var monitor = new Monitor(name);
				monitor.init(this);
				this._monitors.insert(name, (owned)monitor);
				this.monitor_added(name);
			}
		}
	}
}