namespace Genesis {
    public class PanelApplication : Gtk.Application {
        private Component _comp;
        private GLib.List<PanelWindow*> _windows;
        private GLib.DBusConnection? _conn = null;

        [DBus(visible = false)]
        public Component component {
            get {
                return this._comp;
            }
        }

        [DBus(visible = false)]
        public GLib.DBusConnection? conn {
            get {
                return this._conn;
            }
        }

        public PanelApplication() {
            Object(application_id: "com.expidus.GenesisPanel");
            this.set_option_context_parameter_string(_("- Genesis Shell Panel Component"));

            this._comp = new Component();
            this._windows = new GLib.List<PanelWindow*>();

            init_widgets();
        }

        private PanelWindow* find(string name) {
            foreach (var win in this._windows) {
                if (win->monitor_name == name) return win;
            }
            return null;
        }

        public override bool dbus_register(GLib.DBusConnection conn, string obj_path) throws GLib.Error {
            if (!base.dbus_register(conn, obj_path)) return false;

            this._conn = conn;

            conn.register_object(obj_path, this._comp);
            return true;
        }

        public override void activate() {
            this._comp.default_id = "genesis_panel";

            this._comp.layout_changed.connect((monitor) => {
                foreach (var win in this._windows) {
                    if (win->monitor_name == monitor) {
                        win->update();
                    }
                }
            });

            this._comp.monitor_changed.connect((monitor, added) => {
                if (added) {
                    if (this.find(monitor) == null) this._windows.append(new PanelWindow(this, monitor));
                } else {
                    var win = this.find(monitor);
                    if (win != null) {
                        this._windows.remove(win);
                        delete win;
                    }
                }
            });

            new GLib.MainLoop().run();
        }
    }

    public static int main(string[] argv) {
        GLib.Intl.setlocale(GLib.LocaleCategory.ALL, ""); 
        GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, DATADIR + "/locale");
        GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain(GETTEXT_PACKAGE);

        GLib.Environment.set_application_name(GETTEXT_PACKAGE);
        GLib.Environment.set_prgname(GETTEXT_PACKAGE);

        Gtk.init(ref argv);
        return new PanelApplication().run(argv);
    }
}

[CCode(cheader_filename="build.h")]
extern const string GETTEXT_PACKAGE;