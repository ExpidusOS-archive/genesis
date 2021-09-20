namespace Genesis {
    public class Shell {
        private Gdk.Display _disp;
        private GLib.List<Component> _components;
        private GLib.HashTable<string, MISDBase?> _misd;
        private GLib.HashTable<string, string?> _monitors;
        private string _comp_dir;
        private ulong _monitor_added;
        private ulong _monitor_removed;

        public string components_dir {
            get {
                return this._comp_dir;
            }
        }

        public Shell() {
            this._comp_dir = DATADIR + "/genesis/components";
            this.init();
        }

        public Shell.with_component_dir(string comp_dir) {
            this._comp_dir = comp_dir;
            this.init();
        }

        ~Shell() {
            this._disp.disconnect(this._monitor_added);
            this._disp.disconnect(this._monitor_removed);
        }

        private void init() {
            this._disp = Gdk.Display.get_default();
            assert(this._disp != null);

            this._components = new GLib.List<Component>();
            this._misd = new GLib.HashTable<string, MISDBase?>(GLib.str_hash, GLib.str_equal);
            this._monitors = new GLib.HashTable<string, string?>(GLib.str_hash, GLib.str_equal);

            this._monitor_added = this._disp.monitor_added.connect(this.monitor_load);

            this._monitor_removed = this._disp.monitor_removed.connect((monitor) => {
                var misd = this._misd.get(this._monitors.get(monitor.get_model()));
                this._monitors.remove(monitor.get_model());

                if (misd != null) {
                    misd.destroy_monitor(this, monitor.get_model());
                }

                foreach (var comp in this._components) {
                    if (comp.dbus != null) {
                        try {
                            comp.dbus.apply_layout(monitor.get_model(), null);
                        } catch (GLib.Error e) {}
                    }
                }
            });
        }

        private void monitor_load(Gdk.Monitor monitor) {
            this._monitors.set(monitor.get_model(), null);

            foreach (var misd_name in this._misd.get_keys()) {
                var misd = this._misd.get(misd_name);
                var misd_monitors = misd.get_monitors(this);
                foreach (var mon in misd_monitors) {
                    if (mon == monitor.get_model()) {
                        this._monitors.set(monitor.get_model(), misd_name);
                        misd.setup_monitor(this, monitor.get_model());
                        break;
                    }
                }

                if (this._monitors.get(monitor.get_model()) != null) break;
            }

            foreach (var comp in this._components) {
                if (comp.dbus != null) {
                    try {
                        comp.dbus.apply_layout(monitor.get_model(), this._monitors.get(monitor.get_model()));
                    } catch (GLib.Error e) {}
                }
            }
        }

        public void load() {
            for (var i = 0; i < this._disp.get_n_monitors(); i++) {
                this.monitor_load(this._disp.get_monitor(i));
            }

            if (this._components.length() == 0) this.dead();
        }

        public Component? get_component(string id) {
            foreach (var comp in this._components) {
                if (comp.id == id) return comp;
            }
            return null;
        }

        public Component? request_component(string id) throws GLib.Error {
            var comp = this.get_component(id);
            if (comp == null) {
                comp = new Component(this, id);
                comp.killed.connect(() => {
                    this._components.remove(comp);
                    if (this._components.length() == 0) this.dead();
                });
                this._components.append(comp);
            }
            return comp;
        }

        public void define_misd(string id, MISDBase misd) {
            if (!this._misd.contains(id)) {
                this._misd.set(id, misd);
            }
        }

        public void to_lua(Lua.LuaVM lvm) {
            lvm.new_table();

            lvm.push_string("_native");
            lvm.push_lightuserdata(this);
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

                var comp = self.get_component(lvm.to_string(2));
                if (comp == null) {
                    lvm.push_nil();
                } else {
                    comp.to_lua(lvm);
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

                try {
                    var comp = self.request_component(lvm.to_string(2));
                    if (comp == null) {
                        lvm.push_nil();
                    } else {
                        comp.to_lua(lvm);
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

                self.define_misd(lvm.to_string(2), new MISDLua(lvm, get_monitors, setup_monitor, destroy_monitor));
                return 0;
            });
            lvm.raw_set(-3);
        }
        
        public signal void dead();
    }
}