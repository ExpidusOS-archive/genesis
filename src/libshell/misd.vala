namespace Genesis {
    public interface MISDBase : GLib.Object {
        public abstract string[] get_monitors(Shell shell);
        public abstract void setup_monitor(Shell shell, string monitor_name);
        public abstract void destroy_monitor(Shell shell, string monitor_name);
    }

    public class MISDLua : GLib.Object, MISDBase {
        private unowned Lua.LuaVM _lvm;
        private int _ref_get_monitors;
        private int _ref_setup_monitor;
        private int _ref_destroy_monitor;

        public MISDLua(Lua.LuaVM lvm, int ref_get_monitors, int ref_setup_monitor, int ref_destroy_monitor) {
            this._lvm = lvm;
            this._ref_get_monitors = ref_get_monitors;
            this._ref_setup_monitor = ref_setup_monitor;
            this._ref_destroy_monitor = ref_destroy_monitor;
        }

        public string[] get_monitors(Shell shell) {
            this._lvm.set_top(0);
            this._lvm.raw_geti(Lua.PseudoIndex.REGISTRY, this._ref_get_monitors);
            shell.to_lua(this._lvm);
            this._lvm.pcall(1, 1, 0);

            string[] monitors = {};
            // TODO: iterate array
            return monitors;
        }

        public void setup_monitor(Shell shell, string monitor_name) {
            this._lvm.set_top(0);
            this._lvm.raw_geti(Lua.PseudoIndex.REGISTRY, this._ref_setup_monitor);
            shell.to_lua(this._lvm);
            this._lvm.push_string(monitor_name);
            this._lvm.pcall(2, 0, 0);
        }

        public void destroy_monitor(Shell shell, string monitor_name) {
            this._lvm.set_top(0);
            this._lvm.raw_geti(Lua.PseudoIndex.REGISTRY, this._ref_destroy_monitor);
            shell.to_lua(this._lvm);
            this._lvm.push_string(monitor_name);
            this._lvm.pcall(2, 0, 0);
        }
    }
}