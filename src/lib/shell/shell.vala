namespace Genesis {
    public class Shell : GLib.Object {
        private GLib.List<Component> _components;
        private GLib.HashTable<string, MISDBase?> _misd;
        private GLib.HashTable<string, string?> _monitors;
        private GLib.HashTable<string, string?> _monitor_overrides;
        private GLib.HashTable<string, string> _components_monitors;
        private string _comp_dir;
        private devident.BaseDaemon _devident;
        private uint _server_obj;
        private uint _watch;
        private GLib.DBusConnection _conn;

        public string components_dir {
            get {
                return this._comp_dir;
            }
            construct {
                this._comp_dir = value;
            }
        }

        public string[] monitors {
            owned get {
                return this._monitors.get_keys_as_array();
            }
        }

        public Component[] components {
            owned get {
                Component[] value = {};
                foreach (var comp in this._components) {
                    value += comp;
                }
                return value;
            }
        }

        public GLib.HashTable<string, string?> monitor_overrides {
            get {
                return this._monitor_overrides;
            }
            set {
                this._monitor_overrides.remove_all();
                foreach (var v in value.get_keys()) {
                    var k = value.get(v);
                    this._monitor_overrides.set(v, k);
                }
            }
        }

        construct {
            this._components = new GLib.List<Component>();
            this._misd = new GLib.HashTable<string, MISDBase?>(GLib.str_hash, GLib.str_equal);
            this._monitors = new GLib.HashTable<string, string?>(GLib.str_hash, GLib.str_equal);
            this._monitor_overrides = new GLib.HashTable<string, string?>(GLib.str_hash, GLib.str_equal);
            this._components_monitors = new GLib.HashTable<string, string>(GLib.str_hash, GLib.str_equal);

            try {
                this._devident = GLib.Bus.get_proxy_sync(GLib.BusType.SYSTEM, "com.devident", "/com/devident");
            } catch (GLib.Error e) {
                stderr.printf("Failed to connect to devident %s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                GLib.Process.exit(1);
            }

            this._watch = GLib.Bus.own_name(GLib.BusType.SESSION, "com.expidus.GenesisShell", GLib.BusNameOwnerFlags.NONE, (conn, name) => {
                this._conn = conn;
                try {
                    this._server_obj = conn.register_object("/com/expidus/GenesisShell", new ShellServer(this));
                } catch (GLib.Error e) {
                    stderr.printf("Failed to register object %s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                }
            }, null, () => {});
        }

        public Shell() {
            Object(components_dir: DATADIR + "/genesis/components");
        }

        public Shell.with_component_dir(string comp_dir) {
            Object(components_dir: comp_dir);
        }

        ~Shell() {
            if (this._conn != null) {
                this._conn.unregister_object(this._server_obj);
            }

            GLib.Bus.unown_name(this._watch);
        }

        public void monitor_load(string monitor) {
            this._monitors.set(monitor, null);
            var has_override = this._monitor_overrides.contains(monitor) && this._monitor_overrides.get(monitor) != null;

            if (has_override) {
                var misd_name = this._monitor_overrides.get(monitor);
                var misd = this._misd.get(misd_name);
                if (misd != null) {
                    this._monitors.set(monitor, misd_name);
                    misd.setup_monitor(this, monitor);
                }
            }

            if (this._monitors.get(monitor) == null) {
                foreach (var misd_name in this._misd.get_keys()) {
                    var misd = this._misd.get(misd_name);
                    var misd_monitors = misd.get_monitors(this);
                    foreach (var mon in misd_monitors) {
                        if (mon == monitor) {
                            this._monitors.set(monitor, misd_name);
                            misd.setup_monitor(this, monitor);
                            break;
                        }
                    }

                    if (this._monitors.get(monitor) != null) break;
                }
            }

            foreach (var comp in this._components) {
                if (comp.dbus != null) {
                    if (this._components_monitors.contains(comp.id)) {
                        var val = this._monitors.get(monitor);
                        if (this._components_monitors.get(comp.id).contains(val)) {
                            try {
                                comp.dbus.apply_layout(monitor, val);
                                comp.dbus.load_layout(monitor);
                            } catch (GLib.Error e) {
                                stderr.printf("Failed to apply and load: %s (%d) %s\n", e.domain.to_string(), e.code, e.message);
                            }
                        }
                    }
                }
            }
        }

        public void monitor_unload(string monitor) {
            var misd = this._misd.get(this._monitors.get(monitor));
            this._monitors.remove(monitor);

            if (misd != null) {
                misd.destroy_monitor(this, monitor);
            }

            foreach (var comp in this._components) {
                if (comp.dbus != null) {
                    try {
                        comp.dbus.apply_layout(monitor, "");
                    } catch (GLib.Error e) {}
                }
            }
        }

        public void load(string[] monitors) {
            foreach (var mon in monitors) {
                this.monitor_load(mon);
            }

            if (this._components.length() == 0) this.dead();
        }

        public Component? get_component(string id) {
            foreach (var comp in this._components) {
                if (comp.id == id) return comp;
            }
            return null;
        }

        public Component? request_component(string id, string? def) throws GLib.Error {
            var comp = this.get_component(id);
            if (comp == null) {
                comp = new Component(this, id);
                comp.killed.connect(() => {
                    this._components.remove(comp);
                    if (this._components.length() == 0) this.dead();
                });
                if (def != null) {
                    if (!this._components_monitors.contains(id)) {
                        this._components_monitors.set(id, def);
                    } else {
                        var a = this._components_monitors.get(id).split(":");
                        a += def;
                        this._components_monitors.set(id, string.joinv(":", a));
                    }
                }
                foreach (var key in this._monitors.get_keys()) {
                    if (comp.dbus != null) {
                        if (this._components_monitors.contains(id)) {
                            var val = this._monitors.get(key);
                            if (this._components_monitors.get(id).contains(val)) {
                                comp.dbus.apply_layout(key, val == null ? "" : val);
                                comp.dbus.load_layout(key);
                            }
                        }
                    }
                }
                this._components.append(comp);
            }
            return comp;
        }

        public void shutdown() {
            foreach (var comp in this._components) comp.shutdown();
        }

        public void define_misd(MISDBase misd) {
            if (!this._misd.contains(misd.name)) {
                this._misd.set(misd.name, misd);
            }
        }

        public void to_lua(Lua.LuaVM lvm, string? misd_name) {
            lvm.new_table();

            lvm.push_string("_native");
            lvm.push_lightuserdata(this);
            lvm.raw_set(-3);

            if (misd_name != null) {
                lvm.push_string("_misd_name");
                lvm.push_string(misd_name);
                lvm.raw_set(-3);
            }

            lvm.push_string("get_device");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 1) {
                    lvm.push_literal("Invalid argument count");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Invalid argument #1: expected a table");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                var self = (Shell)lvm.to_userdata(2);

                try {
                    var dev = self._devident.get_device();

                    lvm.new_table();

                    lvm.push_string("_native");
                    lvm.push_lightuserdata(dev);
                    lvm.raw_set(-3);

                    lvm.push_string("id");
                    lvm.push_string(dev.get_id());
                    lvm.raw_set(-3);

                    lvm.push_string("name");
                    lvm.push_string(dev.get_name());
                    lvm.raw_set(-3);

                    lvm.push_string("manufacturer");
                    lvm.push_string(dev.get_manufacturer());
                    lvm.raw_set(-3);

                    lvm.push_string("device_type");

                    switch (dev.get_device_type()) {
                        case devident.DeviceType.PHONE:
                            lvm.push_string("phone");
                            break;
                        case devident.DeviceType.LAPTOP:
                            lvm.push_string("laptop");
                            break;
                        case devident.DeviceType.DESKTOP:
                            lvm.push_string("desktop");
                            break;
                        case devident.DeviceType.SERVER:
                            lvm.push_string("server");
                            break;
                        case devident.DeviceType.UNKNOWN:
                        default:
                            lvm.push_string("unknown");
                            break;
                    }

                    lvm.raw_set(-3);

                    lvm.push_string("components");
                    lvm.new_table();

                    var comps = dev.get_components();
                    var i = 1;
                    foreach (var comp in comps) {
                        lvm.push_number(i++);
                        lvm.new_table();

                        switch (comp.get_category()) {
                            case devident.ComponentCategory.TOUCH_DISPLAY:
                                {
                                    var touch_disp = GLib.Bus.get_proxy_sync<devident.TouchDisplay>(GLib.BusType.SYSTEM, "com.devident", "/com/devident/device/%s/component/%s".printf(dev.get_id(), comp.get_id()));
                                    lvm.push_string("input_path");
                                    lvm.push_string(touch_disp.get_input());
                                    lvm.raw_set(-3);

                                    var disp = touch_disp.get_display();
                                    lvm.push_string("display_name");
                                    lvm.push_string(disp.get_name());
                                    lvm.raw_set(-3);
                                }
                                break;
                            default:
                                break;
                        }

                        lvm.set_table(4);
                    }

                    lvm.raw_set(-3);
                } catch (GLib.Error e) {
                    lvm.push_string("%s (%d): %s".printf(e.domain.to_string(), e.code, e.message));
                    lvm.error();
                    return 0;
                }
                return 1;
            });
            lvm.raw_set(-3);

            lvm.push_string("get_monitors");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 1) {
                    lvm.push_literal("Invalid argument count");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Invalid argument #1: expected a table");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                var self = (Shell)lvm.to_userdata(2);

                lvm.new_table();
                var i = 1;
                foreach (var monitor in self._monitors.get_keys()) {
                    lvm.push_number(i++);
                    lvm.push_string(monitor);
                    lvm.set_table(3);
                }
                return 1;
            });
            lvm.raw_set(-3);

            lvm.push_string("get_component");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 2) {
                    lvm.push_literal("Invalid argument count");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Invalid argument #1: expected a table");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(2) != Lua.Type.STRING) {
                    lvm.push_literal("Invalid argument #2: expected a string");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                var self = (Shell)lvm.to_userdata(3);

                string? _misd_name = null;
                lvm.get_field(1, "_misd_name");
                if (lvm.type(4) == Lua.Type.STRING) {
                    _misd_name = lvm.to_string(4);
                }

                var comp_id = lvm.to_string(2);
                var comp = self.get_component(comp_id);
                if (comp == null) {
                    lvm.push_nil();
                } else {
                    comp.to_lua(lvm, _misd_name);
                }
                return 1;
            });
            lvm.raw_set(-3);

            lvm.push_string("request_component");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 2) {
                    lvm.push_literal("Invalid argument count");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Invalid argument #1: expected a table");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(2) != Lua.Type.STRING) {
                    lvm.push_literal("Invalid argument #2: expected a string");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                var self = (Shell)lvm.to_userdata(3);

                string? _misd_name = null;
                lvm.get_field(1, "_misd_name");
                if (lvm.type(4) == Lua.Type.STRING) {
                    _misd_name = lvm.to_string(4);
                }

                try {
                    var comp = self.request_component(lvm.to_string(2), _misd_name);
                    if (comp == null) {
                        lvm.push_nil();
                    } else {
                        comp.to_lua(lvm, _misd_name);
                    }
                } catch (GLib.Error e) {
                    lvm.push_string("%s (%d): %s".printf(e.domain.to_string(), e.code, e.message));
                    lvm.error();
                    return 0;
                }
                return 1;
            });
            lvm.raw_set(-3);

            lvm.push_string("define_misd");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 5) {
                    lvm.push_literal("Invalid argument count");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Invalid argument #1: expected a table");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(2) != Lua.Type.STRING) {
                    lvm.push_literal("Invalid argument #2: expected a string");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(3) != Lua.Type.FUNCTION) {
                    lvm.push_literal("Invalid argument #3: expected a function");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(4) != Lua.Type.FUNCTION) {
                    lvm.push_literal("Invalid argument #4: expected a function");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(5) != Lua.Type.FUNCTION) {
                    lvm.push_literal("Invalid argument #5: expected a function");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                var self = (Shell)lvm.to_userdata(6);

                lvm.push_value(3);
                var get_monitors = lvm.reference(Lua.PseudoIndex.REGISTRY);

                lvm.push_value(4);
                var setup_monitor = lvm.reference(Lua.PseudoIndex.REGISTRY);

                lvm.push_value(5);
                var destroy_monitor = lvm.reference(Lua.PseudoIndex.REGISTRY);

                self.define_misd(new MISDLua(lvm.to_string(2), lvm, get_monitors, setup_monitor, destroy_monitor));
                return 0;
            });
            lvm.raw_set(-3);
        }
        
        public signal void dead();
    }

    [DBus(name = "com.expidus.GenesisShell")]
    public interface ShellClient : GLib.Object {
        public abstract string[] monitors { owned get; }
        public abstract string[] components { owned get; }
        public abstract GLib.HashTable<string, string> monitor_overrides { owned get; }

        public abstract void shutdown() throws GLib.DBusError, GLib.IOError;
        public abstract void override_monitor(string monitor, string layout) throws GLib.DBusError, GLib.IOError;
    }

    [DBus(name = "com.expidus.GenesisShell")]
    public class ShellServer : GLib.Object {
        private Shell _shell;

        [DBus(visible = false)]
        public Shell shell {
            get {
                return this._shell;
            }
            construct {
                this._shell = value;
            }
        }

        public string[] monitors {
            owned get {
                return this.shell.monitors;
            }
        }

        public string[] components {
            owned get {
                string[] value = {};
                foreach (var comp in this.shell.components) {
                    value += comp.id;
                }
                return value;
            }
        }

        public GLib.HashTable<string, string> monitor_overrides {
            get {
                return this.shell.monitor_overrides;
            }
        }

        construct {
            assert(this.shell != null);
        }

        public ShellServer(Shell shell) {
            Object(shell: shell);
        }

        public void shutdown() throws GLib.DBusError, GLib.IOError {
            this.shell.shutdown();
            this.shell.dead();
        }

        public void override_monitor(string monitor, string layout) throws GLib.DBusError, GLib.IOError {
            this.shell.monitor_unload(monitor);

            if (layout.length == 0) {
                this.shell.monitor_overrides.remove(monitor);
            } else {
                this.shell.monitor_overrides.set(monitor, layout);
            }

            var shell_type = typeof (Shell);
            var ocl = (GLib.ObjectClass)shell_type.class_ref();
            foreach (var prop in ocl.list_properties()) {
                if (prop.get_name() == "monitor-overrides") {
                    this.shell.notify["monitor-overrides"](prop);
                    break;
                }
            }

            this.shell.monitor_load(monitor);
        }
    }
}