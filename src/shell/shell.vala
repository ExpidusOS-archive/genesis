namespace Genesis {
    [DBus(name = "com.expidus.Genesis")]
    public class Shell : Gtk.Application {
        private ShellBackend* _backend = null;
        private Lua.LuaVM _lvm;
        private GLib.MainLoop _loop;
        
        protected bool arg_version = false;
        protected string arg_backend = "x11";

        public Shell() {
            Object(application_id: "com.expidus.Genesis");

            GLib.OptionEntry[] options = new GLib.OptionEntry[2];
            options[0] = { "version", 'v', 0, GLib.OptionArg.NONE, ref this.arg_version, _("Display version string"), null };
            options[1] = { "backend", 0, 0, GLib.OptionArg.STRING, ref this.arg_backend, _("Display backend to use"), "BACKEND" };
            this.add_main_option_entries(options);
            this.set_option_context_parameter_string(_("- Genesis Shell"));
        }

        protected override void activate() {
            if (this.arg_version) {
                stdout.printf(_("Version: %s\n"), VERSION);
                return;
            }

            var main_ctx = GLib.MainContext.@default();
            assert(main_ctx.acquire());

            this._loop = new GLib.MainLoop(main_ctx, false);

            switch (this.arg_backend) {
                case "x11":
                    try {
                        this._backend = new Genesis.X11.Backend(this);
                    } catch (GLib.Error error) {
                        stderr.printf("%s (%d): %s\n", error.domain.to_string(), error.code, error.message);
                        GLib.Process.exit(1);
                    }
                    break;
                default:
                    stderr.printf(_("Invalid display backend: %s\n"), this.arg_backend);
                    GLib.Process.exit(1);
            }

            this._lvm = new Lua.LuaVM.with_alloc_func((ptr, osize, nsize) => {
                if (nsize == 0) {
                    GLib.free(ptr);
                    return null;
                }

                return GLib.realloc(ptr, nsize);
            });

            this._lvm.open_libs();

            this._lvm.new_table();

            this._lvm.push_string("_native");
            this._lvm.push_lightuserdata(this);
            this._lvm.raw_set(-3);

            this._lvm.push_string("VERSION");
            this._lvm.push_string(VERSION);
            this._lvm.raw_set(-3);

            this._lvm.push_string("get_monitors");
            this._lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 0) {
                    lvm.push_literal("Expected no arguments");
                    lvm.error();
                    return 0;
                }

                lvm.get_global("shell");
                lvm.get_field(1, "_native");

                Shell self = (Shell)lvm.to_userdata(2);
                
                lvm.new_table();
                var i = 1;
                foreach (var monitor in self._backend->monitors) {
                    lvm.push_integer(i++);
                    monitor.to_lua(lvm);
                    lvm.set_table(-3);
                }
                return 1;
            });
            this._lvm.raw_set(-3);

            this._lvm.push_string("types");
            this._lvm.new_table();

            this._lvm.push_string("desktop");
            this._lvm.push_string(typeof (BaseDesktop).name());
            this._lvm.raw_set(-3);

            this._lvm.raw_set(-3);

            this._lvm.set_global("shell");

            assert(this._backend != null);

            foreach (var monitor in this._backend->monitors) {
                monitor.connection_changed.connect(() => {
                    // TODO: create a desktop for this monitor
                });

                if (monitor.connected) monitor.connection_changed();
            }

            if (this._lvm.do_string("""
local status, lgi = pcall(require, "lgi")
if status then
  shell.types.desktop = lgi.GObject.Type.from_name(shell.types.desktop)
end
""")) {
                stderr.printf("Failed to run lua: %s\n", this._lvm.to_string(-1));
            }

            this._loop.run();
        }

        protected override void run_mainloop() {
            this._loop.run();
        }

        protected override void shutdown() {
            base.shutdown();
            delete this._backend;
        }
    }

    public static int main(string[] args) {
        GLib.Intl.setlocale(GLib.LocaleCategory.ALL, ""); 
        GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, DATADIR + "/locale");
        GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain(GETTEXT_PACKAGE);

        GLib.Environment.set_application_name(GETTEXT_PACKAGE);
        GLib.Environment.set_prgname(GETTEXT_PACKAGE);
        return new Shell().run(args);
    }
}