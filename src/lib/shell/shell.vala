namespace GenesisShell {
	private struct ModuleState {
		public Peas.PluginInfo info;
		public uint obj_id;
	}

	private delegate bool LayoutFilter(GenesisCommon.Module module, GenesisCommon.Layout layout);

	[DBus(name = "com.expidus.genesis.Shell")]
	public class Shell : GenesisCommon.Shell, GLib.Initable {
		private Peas.Engine _engine;
		private Peas.ExtensionSet _extensions;
		private GLib.HashTable<string, ModuleState?> _plugins;
		private GLib.HashTable<string, Monitor> _monitors;
		private GLib.HashTable<string, Window> _windows;
		private GLib.HashTable<string, Layout> _module_layouts;
		private GLib.HashTable<string, GLib.List<string>> _monitor_overrides;
		private GLib.DBusConnection? _dbus_conn;
		private GLib.Settings _settings;
		private uint _obj_id;
		private uint _own_id;
		private bool _loading_modules = false;

		public override string[] monitors {
			owned get {
				return this._monitors.get_keys_as_array();
			}
		}

		public override string[] modules {
			owned get {
				return this._plugins.get_keys_as_array();
			}
		}

		public override string[] layouts {
			owned get {
				string[] val = {};
				foreach (var value in this._module_layouts.get_values()) val += value.name;
				return val;
			}
		}

		public override string[] windows {
			owned get {
				return this._windows.get_keys_as_array();
			}
		}

		public override GenesisCommon.ShellInstanceType instance_type {
			get {
				return GenesisCommon.ShellInstanceType.WM;
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
			this._settings = new GLib.Settings("com.expidus.genesis.shell");

			this._plugins = new GLib.HashTable<string, ModuleState?>(GLib.str_hash, GLib.str_equal);
			this._monitors = new GLib.HashTable<string, Monitor>(GLib.str_hash, GLib.str_equal);
			this._windows = new GLib.HashTable<string, Window>(GLib.str_hash, GLib.str_equal);
			this._module_layouts = new GLib.HashTable<string, Layout>(GLib.str_hash, GLib.str_equal);
			this._monitor_overrides = new GLib.HashTable<string, GLib.List<string>>(GLib.str_hash, GLib.str_equal);

			this._engine = new Peas.Engine();
			this._engine.enable_loader("lua5.1");
			this._engine.enable_loader("python3");
			this._engine.add_search_path(GenesisCommon.LIBDIR + "/genesis/modules/", GenesisCommon.DATADIR + "/genesis/modules/");

			this._extensions = new Peas.ExtensionSet(this._engine, typeof (GenesisShell.Module), "object", this);
			this._extensions.extension_added.connect((info, obj) => {
				var enabled_modules = this._settings.get_strv("enabled-modules");

				if (!this._plugins.contains(info.get_module_name()) && info.get_module_name() in enabled_modules) {
					var module = (Module)obj;
					ModuleState state = { info, 0 };
					
					try {
						if (this._dbus_conn != null) state.obj_id = this._dbus_conn.register_object("/com/expidus/genesis/shell/module/%s".printf(info.get_module_name().replace("-", "")), module);
					} catch (GLib.IOError e) {
						GLib.error("Failed to register module \"%s\" on DBus (%s:%d): %s", info.get_module_name(), e.domain.to_string(), e.code, e.message);
					}

					this._plugins.insert(info.get_module_name(), state);
					GLib.debug("Registered module \"%s\"", info.get_module_name());

					var activatable = obj as Peas.Activatable;
					if (activatable != null) activatable.activate();
					this.module_added(info.get_module_name());

					if (this._module_layouts.contains(info.get_module_name()) && !this._loading_modules) {
						var layout = this._module_layouts.get(info.get_module_name());
						try {
							foreach (var monitor_name in layout.monitors) {
								this.init_monitor(monitor_name);
							}

							foreach (var monitor_name in this.get_monitors_for_layout_overrides(layout.name)) {
								this.init_monitor(monitor_name);
							}
						} catch (GLib.Error e) {
							GLib.error("Failed to attach layout \"%s\" from \"%s\" (%s:%d): %s", layout.name, info.get_module_name(), e.domain.to_string(), e.code, e.message);
						}
					}
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
							foreach (var monitor in this._monitors.get_values()) {
								monitor.detach_layout(module, layout);
							}

							this.remove_layout(module, layout);
						} catch (GLib.Error e) {
							GLib.error("Failed to remove and detach layout \"%s\" from module \"%s\" (%s:%d): %s", layout.name, info.get_module_name(), e.domain.to_string(), e.code, e.message);
						}
					}

					var state = this._plugins.get(info.get_module_name());
					if (this._dbus_conn != null && state.obj_id > 0) {
						this._dbus_conn.unregister_object(state.obj_id);
					}

					this._plugins.remove(info.get_module_name());
					this.module_removed(info.get_module_name());
					GLib.debug("Unregistered module \"%s\"", info.get_module_name());
				}
			});

			this._settings.changed["enabled-modules"].connect(() => {
				var enabled_modules = this._settings.get_strv("enabled-modules");
				foreach (var info in this._engine.get_plugin_list()) {
					if (info.get_module_name() in enabled_modules) {
						this._engine.try_load_plugin(info);
					}
				}

				foreach (var m in this.modules) {
					if (m in enabled_modules) {
						var info = this._engine.get_plugin_info(m);
						var obj = this._extensions.get_extension(info);
						this._extensions.extension_removed(info, obj);
						this._engine.try_unload_plugin(info);
					}
				}
			});

			this._settings.changed["monitor-overrides"].connect(() => {
				foreach (var monitor_name in this.monitors) this.monitor_overrides_load(monitor_name);
			});

			this.monitor_overrides_load.connect((name) => {
				var overrides = this._settings.get_value("monitor-overrides");
				for (var i = 0; i < overrides.n_children(); i++) {
					var entry = overrides.get_child_value(i);
					var monitor_name = entry.get_child_value(0).get_string();
					if (monitor_name != name) break;
					var layouts = entry.get_child_value(1);

					var list = new GLib.List<string>();

					for (var x = 0; x < layouts.n_children(); x++) {
						var layout_name = layouts.get_child_value(x).get_string();
						list.append(layout_name);
					}

					this._monitor_overrides.set(monitor_name, (owned)list);
				}
			});
		}

		public Shell() {
			Object();
		}

		public Shell.with_dbus_connection(GLib.DBusConnection dbus_connection) {
			Object(dbus_connection: dbus_connection);
		}

		~Shell() {
			if (this._obj_id > 0) {
				this._dbus_conn.unregister_object(this._obj_id);
				this._obj_id = 0;
			}

			if (this._own_id > 0) {
				GLib.Bus.unown_name(this._own_id);
				this._own_id = 0;
			}
		}

		[DBus(visible = false)]
		public void add_window(owned Window win) throws GLib.Error {
			if (!this._windows.contains(win.to_string())) {
				win.init(this);
				this._windows.insert(win.to_string(), (owned)win);
			}
		}

		[DBus(visible = false)]
		public unowned Window? find_window(string key) {
			return this._windows.get(key);
		}

		[DBus(visible = false)]
		public void remove_window(string key) {
			if (this._windows.contains(key)) {
				var win = this.find_window(key);
				this._windows.remove(key);
				win.destroy();
			}
		}

		[DBus(visible = false)]
		public override unowned GenesisCommon.Monitor? find_monitor(string name) {
			return this._monitors.get(name);
		}

		[DBus(visible = false)]
		public void add_monitor(owned Monitor monitor) throws GLib.Error {
			if (!this._monitors.contains(monitor.name)) {
				monitor.init(this);
				string name = monitor.name;
				this._monitors.insert(name, (owned)monitor);
				this.monitor_added(name);
				this.monitor_overrides_load(name);

				this.init_monitor(name);
			}
		}

		public void remove_monitor(string name) throws GLib.Error {
			if (this._monitors.contains(name)) {
				var monitor = this.find_monitor(name) as Monitor;
				this._monitors.remove(name);
				this.monitor_removed(name);
				monitor.destroy();
				this._monitor_overrides.remove(name);
			}
		}

		public override void rescan_modules() throws GLib.Error {
			this._loading_modules = true;
			GLib.debug("Loading modules from " + GenesisCommon.LIBDIR + "/genesis/modules/");
			this._engine.rescan_plugins();

			try {
				foreach (var info in this._engine.get_plugin_list()) this._engine.try_load_plugin(info);
			} finally {
				this._loading_modules = false;
			}

			foreach (var monitor_name in this.monitors) {
				this.init_monitor(monitor_name);
			}
		}

		public override bool load_module(string name) throws GLib.Error {
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
			string? name = null;
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
		public override void define_layout(GenesisCommon.Module _module, GenesisCommon.Layout _layout) throws GenesisCommon.ShellError {
			var module = _module as Module;
			if (module == null) throw new GenesisCommon.ShellError.INVALID_MODULE("Module is not a shell type module");

			var layout = _layout as Layout;
			if (layout == null) throw new GenesisCommon.ShellError.INVALID_MODULE("Layout is not a shell type layout");

			string? name;
			if (!this.check_module(module, out name)) throw new GenesisCommon.ShellError.INVALID_MODULE("Module authenticity cannot be verified");
			if (this._module_layouts.contains(name)) throw new GenesisCommon.ShellError.INVALID_MODULE("Module already registered a layout");

			foreach (var value in this._module_layouts.get_values()) {
				if (value.name == layout.name) throw new GenesisCommon.ShellError.INVALID_LAYOUT("Layout is already provided by a module");
			}

			layout.init(this);
			this._module_layouts.set(name, layout);
			this.layout_added(layout.name);

			if (!this._loading_modules) {
				foreach (var monitor in layout.monitors) this.init_monitor(monitor);
			}
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

		public override bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
			if (base.init(cancellable)) {
				if (this._dbus_conn == null) {
					GLib.debug("No DBus connection was given, creating our own connection");
					this._dbus_conn = GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable);
				}

				this._own_id = GLib.Bus.own_name_on_connection(this._dbus_conn, "com.expidus.genesis.Shell", GLib.BusNameOwnerFlags.DO_NOT_QUEUE);
				this._obj_id = this._dbus_conn.register_object("/com/expidus/genesis/shell", (GenesisCommon.Shell)this);
				return true;
			}
			return false;
		}

		private void try_init_monitor_module(Monitor monitor, GenesisCommon.Layout layout, GenesisCommon.Module module, LayoutFilter filter) throws GenesisCommon.ShellError {
			if (filter(module, layout) && monitor.name in layout.monitors) {
				if (monitor.find_layout_provides(GenesisCommon.LayoutFlags.WINDOW_DECORATION) == null && (layout.flags & GenesisCommon.LayoutFlags.WINDOW_DECORATION) == GenesisCommon.LayoutFlags.WINDOW_DECORATION) {
					monitor.attach_layout(module, layout);
				}

				if (monitor.find_layout_provides(GenesisCommon.LayoutFlags.DESKTOP) == null && (layout.flags & GenesisCommon.LayoutFlags.DESKTOP) == GenesisCommon.LayoutFlags.DESKTOP) {
					monitor.attach_layout(module, layout);
				}

				if (monitor.find_layout_provides(GenesisCommon.LayoutFlags.PANEL) == null && (layout.flags & GenesisCommon.LayoutFlags.PANEL) == GenesisCommon.LayoutFlags.PANEL) {
					monitor.attach_layout(module, layout);
				}

				if (monitor.find_layout_provides(GenesisCommon.LayoutFlags.POLKIT_DIALOG) == null && (layout.flags & GenesisCommon.LayoutFlags.POLKIT_DIALOG) == GenesisCommon.LayoutFlags.POLKIT_DIALOG) {
					monitor.attach_layout(module, layout);
				}
			}
		}

		private void try_init_monitor(Monitor monitor, LayoutFilter filter) throws GenesisCommon.ShellError {
			if (this._monitor_overrides.contains(monitor.name)) {
				foreach (var layout_name in this._monitor_overrides.get(monitor.name)) {
					var layout = this.get_layout_from_name(layout_name);
					if (layout == null) continue;

					var module = this.get_module_for_layout(layout);
					if (module == null) continue;

					this.try_init_monitor_module(monitor, layout, module, filter);
				}
			} else {
				foreach (var module_name in this._module_layouts.get_keys()) {
					var layout = this._module_layouts.get(module_name);
					if (layout == null) continue;

					var module = this.get_module(module_name);
					if (module == null) continue;

					this.try_init_monitor_module(monitor, layout, module, filter);
				}
			}
		}

		private void init_monitor(string name) throws GenesisCommon.ShellError {
			var monitor = this.find_monitor(name) as Monitor;
			if (monitor == null) return;

			this.try_init_monitor(monitor, (module, layout) => layout.try_first && !layout.try_last);
			this.try_init_monitor(monitor, (module, layout) => !layout.try_first && !layout.try_last);
			this.try_init_monitor(monitor, (module, layout) => !layout.try_first && layout.try_last);
		}

		private string[] get_monitors_for_layout_overrides(string layout_name) {
			if (this.get_layout_from_name(layout_name) == null) return {};

			string[] values = {};

			foreach (var monitor_name in this._monitor_overrides.get_keys()) {
				unowned var layouts = this._monitor_overrides.get(monitor_name);
				foreach (var layout in layouts) {
					if (layout_name == layout) {
						values += monitor_name;
						break;
					}
				}
			}
			return values;
		}

		[DBus(visible = false)]
		public string[] get_layout_overrides_for_monitor(string monitor_name) {
			if (this.find_monitor(monitor_name) == null) return {};

			if (!this._monitor_overrides.contains(monitor_name)) this._monitor_overrides.set(monitor_name, new GLib.List<string>());

			string[] values = {};
			foreach (var layout in this._monitor_overrides.get(monitor_name)) values += layout;
			return values;
		}

		[DBus(visible = false)]
		public void set_layout_overrides_for_monitor(string monitor_name, string[] values) {
			if (this.find_monitor(monitor_name) == null) return;

			var list = new GLib.List<string>();
			foreach (var v in values) list.append(v);
			this._monitor_overrides.set(monitor_name, (owned)list);
		}
	}
}