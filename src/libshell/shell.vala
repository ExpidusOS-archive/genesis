namespace Genesis {
    public class Shell {
        private GLib.List<Component> _components;
        private GLib.HashTable<string, MISDBase?> _misd;

        public Shell() {
            this._components = new GLib.List<Component>();
            this._misd = new GLib.HashTable<string, MISDBase?>(GLib.str_hash, GLib.str_equal);
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
                this._components.append(comp);
            }
            return comp;
        }

        public void define_mis(string id, MISDBase misd) {
            if (!this._misd.contains(id)) {
                this._misd.set(id, misd);
            }
        }

        public void to_lua(Lua.LuaVM lvm) {
            lvm.new_table();

            lvm.push_string("_native");
            lvm.push_lightuserdata(this);
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
        }
    }
}