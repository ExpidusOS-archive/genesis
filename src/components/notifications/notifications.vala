namespace Genesis {
    public class NotificationsApplication : Gtk.Application {
        private Component _comp;
        private FreedesktopDaemon _fd_daemon;
        private NotificationDaemonServer _genesis_daemon;
        private GLib.DBusConnection? _conn = null;
        private uint _own_id;

        [DBus(visible = false)]
        public GLib.DBusConnection? conn {
            get {
                return this._conn;
            }
        }

        public NotificationsApplication() {
            Object(application_id: "com.expidus.GenesisNotifications");
            this.set_option_context_parameter_string(_("- Genesis Shell Notifications Daemon and Component"));

            this._comp = new Component();
            this._genesis_daemon = new NotificationDaemonServer();
            this._fd_daemon = new FreedesktopDaemon(this._genesis_daemon);

            this._comp.killed.connect(() => {
                GLib.Process.exit(0);
            });

            init_widgets();
        }

        public override bool dbus_register(GLib.DBusConnection conn, string obj_path) throws GLib.Error {
            if (!base.dbus_register(conn, obj_path)) return false;

            this._own_id = GLib.Bus.own_name_on_connection(conn, "org.freedesktop.Notifications", GLib.BusNameOwnerFlags.NONE);

            conn.register_object(obj_path, this._comp);
            conn.register_object(obj_path, this._genesis_daemon);
            conn.register_object("/org/freedesktop/Notifications", this._fd_daemon);

            this._conn = conn;
            return true;
        }

        public override void activate() {
            this._comp.default_id = "genesis_notification";

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
        return new NotificationsApplication().run(argv);
    }
}

[CCode(cheader_filename="build.h")]
extern const string GETTEXT_PACKAGE;