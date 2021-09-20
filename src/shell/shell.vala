public int main(string[] argv) {
    unowned var ctx = Meta.get_option_context();
    try {
        if (!ctx.parse(ref argv)) {
            return 1;
        }
    } catch (GLib.Error e) {
        stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
        return 1;
    }

    Meta.Plugin.manager_set_plugin_type(typeof (Genesis.MetaPlugin));
    Meta.set_wm_name("genesis-wm");

    Meta.init();
    Meta.register_with_session();
    return Meta.run();
}