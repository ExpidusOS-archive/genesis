namespace Genesis {
    public class Component {
        private Shell _shell;
        private string _id;
        private GLib.KeyFile _kf;
        private bool _respawns;
        private GLib.Pid _pid;
        private ComponentDBus? _dbus;

        public ComponentDBus dbus {
            get {
                return this._dbus;
            }
        }

        public string id {
            get {
                return this._id;
            }
        }

        public Component(Shell shell, string id) throws GLib.Error {
            this._shell = shell;
            this._id = id;

            this._kf = new GLib.KeyFile();
            this._kf.load_from_file(this._shell.components_dir + "/%s.ini".printf(id), GLib.KeyFileFlags.NONE);

            this._respawns = this._kf.has_key("Component", "respawns") && this._kf.get_boolean("Component", "respawns");

            this.spawn();
        }

        private void spawn() throws GLib.KeyFileError, GLib.SpawnError, GLib.IOError, ComponentError { 
            if (this._kf.has_group("DBus")) {
                var bus_str = this._kf.get_string("DBus", "bus");
                GLib.BusType bus_type;
                switch (bus_str) {
                    case "system":
                        bus_type = GLib.BusType.SYSTEM;
                        break;
                    case "session":
                        bus_type = GLib.BusType.SESSION;
                        break;
                    default:
                        throw new ComponentError.CONFIGURATION_ERROR("Invalid DBus bus type \"%s\"", bus_str);
                }

                this._dbus = GLib.Bus.get_proxy_sync(bus_type, this._kf.get_string("DBus", "name"), this._kf.get_string("DBus", "obj_path"));
            } else {
                GLib.Process.spawn_async(null, this._kf.get_string_list("Component", "exec"), null,
                    GLib.SpawnFlags.STDERR_TO_DEV_NULL | GLib.SpawnFlags.STDOUT_TO_DEV_NULL,
                    null, out this._pid);

                GLib.ChildWatch.add(this._pid, (pid, stat) => {
                    GLib.Process.close_pid(pid);

                    if (this._respawns) {
                        try {
                            this.spawn();
                        } catch (GLib.Error e) {
                            stderr.printf("Component failure (%s): %s (%d): %s\n", this.id, e.domain.to_string(), e.code, e.message);
                            this.killed();
                        }
                    } else {
                        this.killed();
                    }
                });
            }
        }

        public void to_lua(Lua.LuaVM lvm) {
            lvm.new_table();

            lvm.push_string("_native");
            lvm.push_lightuserdata(this);
            lvm.raw_set(-3);

            if (this._dbus != null) {
                lvm.push_string("define_layout");
                lvm.push_cfunction((lvm) => {
                    if (lvm.get_top() != 3) {
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

                    if (lvm.type(3) != Lua.Type.STRING) {
                        lvm.push_literal("Invalid argument #3: expected a string");
                        lvm.error();
                        return 0;
                    }

                    lvm.get_field(1, "_native");
                    var self = (Component)lvm.to_userdata(4);

                    try {
                        self.dbus.define_layout(lvm.to_string(2), lvm.to_string(3));
                    } catch (GLib.Error e) {
                        lvm.push_string("%s (%d): %s".printf(e.domain.to_string(), e.code, e.message));
                        lvm.error();
                    }
                    return 0;
                });
                lvm.raw_set(-3);
            }
        }

        public signal void killed();
    }

    [DBus(name = "com.expidus.GenesisComponent")]
    public interface ComponentDBus : GLib.Object {
        [DBus(name = "DefaultID")]
        public abstract string default_id { owned get; set; }

        [DBus(name = "ApplyLayout")]
        public abstract void apply_layout(string monitor, string? misd) throws GLib.Error;

        [DBus(name = "DefineLayout")]
        public abstract void define_layout(string misd, string layout) throws GLib.Error;

        [DBus(name = "LoadLayout")]
        public abstract void load_layout(string monitor) throws GLib.Error;
 
        [DBus(name = "WidgetSimpleEvent")]
        public signal void widget_simple_event(string path, string name);
    }
}