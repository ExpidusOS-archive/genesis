namespace Genesis {
    public errordomain ShellError {
        BACKEND
    }

    public struct RectangleUint32 {
        public uint32 x;
        public uint32 y;
        public uint32 width;
        public uint32 height;
    }

    public struct RectangleUint16 {
        public uint16 x;
        public uint16 y;
        public uint16 width;
        public uint16 height;
    }

    public interface GenericObject : GLib.Object {
        public abstract string to_string();
        public abstract void to_lua(Lua.LuaVM lvm);
    }

    public interface ShellBackend : GLib.Object {
        public abstract GLib.List<weak MonitorBackend> monitors { owned get; }
    }

    public abstract class MonitorBackend : GLib.Object, GenericObject {
        public abstract string name { get; }
        public abstract bool connected { get; }
        public abstract RectangleUint32 physical_rect { get; }
        public abstract RectangleUint16 resolution { get; }

        public signal void connection_changed();

        public string to_string() {
            return "%s (%s)".printf(this.name, this.connected ? "Connected, %lumm x %lumm, %lupx x %lupx @ (%lupx, %lupx)".printf(this.physical_rect.width, this.physical_rect.height, this.resolution.width, this.resolution.height, this.resolution.x, this.resolution.y) : "Disconnected");
        }

        public void to_lua(Lua.LuaVM lvm) {
            lvm.new_table();

            lvm.push_string("_native");
            lvm.push_lightuserdata(this);
            lvm.raw_set(-3);

            lvm.push_string("name");
            lvm.push_string(this.name);
            lvm.raw_set(-3);

            lvm.push_string("is_connected");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 1) {
                    lvm.push_literal("Expecting exactly 1 argument");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Argument #1: invalid type, expecting table");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                MonitorBackend self = (MonitorBackend)lvm.to_userdata(2);
                lvm.push_boolean(self.connected ? 1 : 0);
                return 1;
            });
            lvm.raw_set(-3);

            lvm.push_string("get_physical_rect");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 1) {
                    lvm.push_literal("Expecting exactly 1 argument");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Argument #1: invalid type, expecting table");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                MonitorBackend self = (MonitorBackend)lvm.to_userdata(2);

                lvm.push_integer((int)self.physical_rect.x);
                lvm.push_integer((int)self.physical_rect.y);
                lvm.push_integer((int)self.physical_rect.width);
                lvm.push_integer((int)self.physical_rect.height);
                return 4;
            });
            lvm.raw_set(-3);

            lvm.push_string("get_resolution");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 1) {
                    lvm.push_literal("Expecting exactly 1 argument");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Argument #1: invalid type, expecting table");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                MonitorBackend self = (MonitorBackend)lvm.to_userdata(2);

                lvm.push_integer(self.resolution.x);
                lvm.push_integer(self.resolution.y);
                lvm.push_integer(self.resolution.width);
                lvm.push_integer(self.resolution.height);
                return 4;
            });
            lvm.raw_set(-3);

            lvm.push_string("to_string");
            lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 1) {
                    lvm.push_literal("Expecting exactly 1 argument");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.TABLE) {
                    lvm.push_literal("Argument #1: invalid type, expecting table");
                    lvm.error();
                    return 0;
                }

                lvm.get_field(1, "_native");
                MonitorBackend self = (MonitorBackend)lvm.to_userdata(2);
                lvm.push_string(self.to_string());
                return 1;
            });
            lvm.raw_set(-3);
        }
    }
}