namespace Genesis {
    [DBus(name = "com.expidus.Genesis")]
    public class Shell : Gtk.Application {
        private ShellBackend* _backend = null;
        
        public bool arg_version = false;
        public string arg_backend = "x11";

        public Shell() {
            Object(application_id: "com.expidus.Genesis");

            GLib.OptionEntry[] options = new GLib.OptionEntry[2];
            options[0] = { "version", 'v', 0, GLib.OptionArg.NONE, ref this.arg_version, _("Display version string"), null };
            options[1] = { "backend", 0, 0, GLib.OptionArg.STRING, ref this.arg_backend, _("Display backend to use"), "BACKEND" };
            this.add_main_option_entries(options);
        }

        protected override void activate() {
            if (this.arg_version) {
                stdout.printf(_("Version: %s\n"), VERSION);
                return;
            }

            switch (this.arg_backend) {
                case "x11":
                    this._backend = new Genesis.X11.Backend(this);
                    break;
                default:
                    stderr.printf(_("Invalid display backend: %s\n"), this.arg_backend);
                    GLib.Process.exit(1);
            }

            assert(this._backend != null);
            foreach (var monitor in this._backend->monitors) {
                monitor.connection_changed.connect(() => {
                    // TODO: create or destroy the desktop
                });
            }
        }

        protected override void shutdown() {
            base.shutdown();
            if (this._backend != null) delete this._backend;
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