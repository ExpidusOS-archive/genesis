namespace Genesis {
    [DBus(name = "com.expidus.Genesis")]
    public class Shell : Gtk.Application {
        private ShellBackend* _backend = null;
        private Lua.LuaVM _lvm;
        private GLib.MainLoop _loop;
        private GLib.HashTable<string, GLib.Type> _types;
        private GLib.HashTable<string, BaseDesktop?> _desktops;
        
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
            this._types = new GLib.HashTable<string, GLib.Type>(GLib.str_hash, GLib.str_equal);
            this._desktops = new GLib.HashTable<string, BaseDesktop?>(GLib.str_hash, GLib.str_equal);

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

            this._lvm.push_string("override_type");
            this._lvm.push_cfunction((lvm) => {
                if (lvm.get_top() != 2) {
                    lvm.push_literal("Expected 2 arguments");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(1) != Lua.Type.STRING) {
                    lvm.push_literal("Invalid argument: expected a string");
                    lvm.error();
                    return 0;
                }

                if (lvm.type(2) != Lua.Type.TABLE) {
                    lvm.push_literal("Invalid argument: expected a table");
                    lvm.error();
                    return 0;
                }

                lvm.get_global("shell");
                lvm.get_field(3, "_native");

                Shell self = (Shell)lvm.to_userdata(4);
                var monitor_name = lvm.to_string(1);

                MonitorBackend? found_monitor = null;
                foreach (var monitor in self._backend->monitors) {
                    if (monitor.name == monitor_name) {
                        found_monitor = monitor;
                        break;
                    }
                }

                if (found_monitor == null) {
                    lvm.push_literal("Invalid monitor name");
                    lvm.error();
                    return 0;
                }

                lvm.push_nil();
                while (lvm.next(2) != 0) {
                    var key = lvm.to_string(-1);

                    if (key != "desktop" && key != "window-frame" && key != "notification") {
                        lvm.push_literal("Invalid value: expected \"desktop\", \"notification\", or \"window-frame\".");
                        lvm.error();
                        return 0;
                    }

                    var full_key = monitor_name + "/" + key;

                    switch (lvm.type(-2)) {
                        case Lua.Type.NIL:
                            switch (key) {
                                case "desktop":
                                    self._types.set(full_key, typeof (BaseDesktop));
                                    break;
                                case "notification":
                                    self._types.set(full_key, typeof (BaseNotification));
                                    break;
                                case "window-frame":
                                    self._types.set(full_key, typeof (BaseWindowFrame));
                                    break;
                            }
                            break;
                        case Lua.Type.TABLE:
                            lvm.get_field(-2, "_native");
                            self._types.set(full_key, (GLib.Type)lvm.to_userdata(lvm.get_top()));
                            break;
                        case Lua.Type.STRING:
                            self._types.set(full_key, GLib.Type.from_name(lvm.to_string(-2)));
                            break;
                        default:
                            lvm.push_literal("Invalid argument: expected a table, nil, or string");
                            lvm.error();
                            return 0;
                    }
                    lvm.pop(1);
                }
                return 0;
            });
            this._lvm.raw_set(-3);

            this._lvm.push_string("types");
            this._lvm.new_table();

            this._lvm.push_string("desktop");
            this._lvm.push_string(typeof (BaseDesktop).name());
            this._lvm.raw_set(-3);

            this._lvm.push_string("notification");
            this._lvm.push_string(typeof (BaseNotification).name());
            this._lvm.raw_set(-3);

            this._lvm.push_string("window_frame");
            this._lvm.push_string(typeof (BaseWindowFrame).name());
            this._lvm.raw_set(-3);

            this._lvm.raw_set(-3);

            this._lvm.set_global("shell");

            assert(this._backend != null);

            foreach (var monitor in this._backend->monitors) {
                this._types.set(monitor.name + "/desktop", typeof (BaseDesktop));
                monitor.connection_changed.connect(() => {
                    if (monitor.connected) {
                        var desktop_type = this._types.get(monitor.name + "/desktop");
                        this._desktops.set(monitor.name, (BaseDesktop)GLib.Object.@new(desktop_type, "shell", this, "monitor", this, null));
                    } else {
                        if (this._desktops.contains(monitor.name)) {
                            this._desktops.remove(monitor.name);
                        }
                    }
                });

                if (monitor.connected) monitor.connection_changed();
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