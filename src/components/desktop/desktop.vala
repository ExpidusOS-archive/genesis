namespace Genesis {
    public class DesktopApplication : Gtk.Application {
        private Component _comp;
        private GLib.List<DesktopWindow*> _windows;
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

        public DesktopApplication() {
            Object(application_id: "com.expidus.GenesisDesktop");
            this.set_option_context_parameter_string(_("- Genesis Shell Desktop Component"));

            this._comp = new Component();
            this._windows = new GLib.List<DesktopWindow*>();

            this._comp.killed.connect(() => {
                GLib.Process.exit(0);
            });

            init_widgets();
        }

        private DesktopWindow* find(string name) {
            foreach (var win in this._windows) {
                if (win->monitor_name == name) return win;
            }
            return null;
        }

        private string? get_xdg_dir(string type) {
            switch (type) {
                case "HOME":
                    return GLib.Environment.get_home_dir();
                case "USER_CACHE":
                    return GLib.Environment.get_user_data_dir();
                case "USER_CONFIG":
                    return GLib.Environment.get_user_config_dir();
                case "USER_DATA":
                    return GLib.Environment.get_user_data_dir();
                default:
                    GLib.UserDirectory dir;
                    switch (type) {
                        case "DESKTOP":
                            dir = GLib.UserDirectory.DESKTOP;
                            break;
                        case "DOCUMENTS":
                            dir = GLib.UserDirectory.DOCUMENTS;
                            break;
                        case "DOWNLOADS":
                            dir = GLib.UserDirectory.DOWNLOAD;
                            break;
                        case "MUSIC":
                            dir = GLib.UserDirectory.MUSIC;
                            break;
                        case "PICTURES":
                            dir = GLib.UserDirectory.PICTURES;
                            break;
                        case "PUBLIC_SHARE":
                            dir = GLib.UserDirectory.PUBLIC_SHARE;
                            break;
                        case "TEMPLATES":
                            dir = GLib.UserDirectory.TEMPLATES;
                            break;
                        case "VIDEOS":
                            dir = GLib.UserDirectory.VIDEOS;
                            break;
                        default:
                            return null;
                    }
                    return GLib.Environment.get_user_special_dir(dir);
            }
        }

        public string? get_xdg_display(string type) {
            switch (type) {
                case "HOME": return "Home";
                case "USER_CACHE": return "Cache";
                case "USER_CONFIG": return "Configuration";
                case "USER_DATA": return "Data";
                case "DESKTOP": return "Desktop";
                case "DOCUMENTS": return "Documents";
                case "DOWNLOADS": return "Downloads";
                case "MUSIC": return "Music";
                case "PICTURES": return "Pictures";
                case "PUBLIC_SHARE": return "Public Share";
                case "TEMPLATES": return "Templates";
                case "VIDEOS": return "Videos";
            }
            return null;
        }

        private void build_menu() {
            // TODO: localizations
            var app_menu = new GLib.Menu();
            {
                var menu = new GLib.Menu();

                menu.append("Settings", "app.settings");
                menu.append("About", "app.about");

                {
                    var submenu = new GLib.Menu();

                    string[] dirs = { "HOME", "DESKTOP", "DOCUMENTS", "DOWNLOADS", "MUSIC", "PICTURES", "VIDEOS" };
                    foreach (var str in dirs) {
                        var dir = this.get_xdg_dir(str);
                        var disp = this.get_xdg_display(str);
                        if (dir == null || disp == null) continue;

                        submenu.append(disp, "app.dir-" + str.down());
                    }

                    menu.append_section(null, submenu);
                }

                app_menu.append_submenu("Genesis", menu);
            }

            app_menu.append_section(null, new GLib.Menu());
            this.set_menubar(app_menu);
        }

        public override void startup() {
            base.startup();

            {
                var action = new GLib.SimpleAction("settings", null);
                action.activate.connect(() => {
                    try {
                        var sysrt = GLib.Bus.get_proxy_sync<SystemRT.SystemRT>(GLib.BusType.SYSTEM, "com.expidus.SystemRT", "/com/expidus/SystemRT");
                        sysrt.spawn({ BINDIR + "/genesis-settings" });
                    } catch (GLib.Error e) {}
                });
                this.add_action(action);
            }

            {
                var action = new GLib.SimpleAction("about", null);
                action.activate.connect(() => {
                    try {
                        var sysrt = GLib.Bus.get_proxy_sync<SystemRT.SystemRT>(GLib.BusType.SYSTEM, "com.expidus.SystemRT", "/com/expidus/SystemRT");
                        sysrt.spawn({ BINDIR + "/genesis-about" });
                    } catch (GLib.Error e) {}
                });
                this.add_action(action);
            }

            {
                string[] dirs = { "home", "desktop", "documents", "downloads", "music", "pictures", "videos" };
                foreach (var dir in dirs) {
                    var action = new GLib.SimpleAction("dir-" + dir, null);
                    action.activate.connect(() => {
                        try {
                            var sysrt = GLib.Bus.get_proxy_sync<SystemRT.SystemRT>(GLib.BusType.SYSTEM, "com.expidus.SystemRT", "/com/expidus/SystemRT");
                            sysrt.spawn({ BINDIR + "/ghostfm", "--open", this.get_xdg_dir(dir.up()) });
                        } catch (GLib.Error e) {}
                    });
                    this.add_action(action);
                }
            }

            this.build_menu();
        }

        public override bool dbus_register(GLib.DBusConnection conn, string obj_path) throws GLib.Error {
            if (!base.dbus_register(conn, obj_path)) return false;

            conn.register_object(obj_path, this._comp);
            this._conn = conn;
            return true;
        }

        public override void activate() {
            this._comp.default_id = "genesis_desktop";

            this._comp.layout_changed.connect((monitor) => {
                foreach (var win in this._windows) {
                    if (win->monitor_name == monitor) {
                        win->update();
                    }
                }
            });

            this._comp.monitor_changed.connect((monitor, added) => {
                if (added) {
                    if (this.find(monitor) == null) this._windows.append(new DesktopWindow(this, monitor));
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
        return new DesktopApplication().run(argv);
    }
}

[CCode(cheader_filename="build.h")]
extern const string GETTEXT_PACKAGE;