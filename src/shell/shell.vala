public int main(string[] argv) {
    Gdk.init(ref argv);

    var lvm = new Lua.LuaVM.with_alloc_func((ptr, osize, nsize) => {
        if (nsize == 0) {
            GLib.free(ptr);
            return null;
        }

        return GLib.realloc(ptr, nsize);
    });

    var shell = new Genesis.Shell();
    var main_loop = new GLib.MainLoop();

    lvm.open_libs();
    shell.to_lua(lvm);
    lvm.set_global("genesis");

    try {
        var dir = GLib.Dir.open(Genesis.DATADIR + "/genesis/misd");
        string? name;

        while ((name = dir.read_name()) != null) {
            var path = Genesis.DATADIR + "/genesis/misd/%s".printf(name);
            if (!GLib.FileUtils.test(path, GLib.FileTest.IS_REGULAR)) continue;

            if (lvm.do_file(path)) {
                stderr.printf("genesis-shell: failed to load \"%s\": %s\n", path, lvm.to_string(-1));
            }
        }
    } catch (GLib.Error e) {
        stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
        return 1;
    }

    shell.load();
    main_loop.run();
    return 0;
}