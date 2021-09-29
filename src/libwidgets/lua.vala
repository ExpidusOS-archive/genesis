namespace Genesis {
    public class LuaBin : Gtk.Bin {
        private Lua.LuaVM _lvm;
        private string? _lua_string = null;
        private string? _lua_file = null;

        public string? lua_string {
            get {
                return this._lua_string;
            }
            construct {
                this._lua_string = value;
                this._lua_file = null;
            }
        }

        public string? lua_file {
            get {
                return this._lua_file;
            }
            construct {
                this._lua_file = value;
                this._lua_string = null;
            }
        }


        public Lua.LuaVM lvm {
            get {
                return this._lvm;
            }
        }

        construct {
            this._lvm = new Lua.LuaVM.with_alloc_func((ptr, osize, nsize) => {
                if (nsize == 0) {
                    GLib.free(ptr);
                    return null;
                }

                return GLib.realloc(ptr, nsize);
            });

            this._lvm.open_libs();

            bind_widget(this._lvm, this);
            this._lvm.set_global("self");

            var r = false;
            if (this.lua_file == null && this.lua_string != null) {
                r = this._lvm.do_string(this.lua_string);
            } else if (this.lua_file != null && this.lua_string == null) {
                r = this._lvm.do_file(this.lua_file);
            }

            if (!r) {
                stderr.printf("Failed to run Lua code: %s", this._lvm.to_string(-1));
            }
        }

        public LuaBin() {
            Object();
        }

        public LuaBin.with_file(string str) {
            Object(lua_file: str);
        }

        public LuaBin.with_string(string str) {
            Object(lua_string: str);
        }

        private static void bind_widget(Lua.LuaVM lvm, Gtk.Widget widget) {
            lvm.new_table();

            lvm.push_string("_native");
            lvm.push_lightuserdata(widget);
            lvm.raw_set(-3);

            lvm.push_string("get_parent");
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
                var self = (Gtk.Widget)lvm.to_userdata(2);
                var parent = self.get_parent();

                if (parent == null) lvm.push_nil();
                else bind_widget(lvm, parent);
                return 1;
            });

            if (widget is Gtk.Container) {
                lvm.push_string("get_children");
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
                    var self = (Gtk.Widget)lvm.to_userdata(2);
                    var container = self as Gtk.Container;

                    if (container == null) {
                        lvm.push_literal("Widget is not a container");
                        lvm.error();
                        return 0;
                    }

                    var i = 1;
                    foreach (var child in container.get_children()) {
                        lvm.push_number(i++);
                        bind_widget(lvm, child);
                        lvm.set_table(3);
                    }
                    return 1;
                });
                lvm.raw_set(-3);
            }
        }
    }
}