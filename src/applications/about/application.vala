namespace GenesisAbout {
    public class Application : Gtk.Application {
        public Application() {
            Object(application_id: "com.expidus.GenesisAbout");
        }

        public override void activate() {
            if (this.get_windows().length() == 0) {
                var win = new Window();
                this.add_window(win);
                win.show_all();
            } else {
                this.get_windows().nth_data(0).present();
            }
        }
    }

    public int main(string[] argv) {
        GLib.Intl.setlocale(GLib.LocaleCategory.ALL, ""); 
        GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, Genesis.DATADIR + "/locale");
        GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain(GETTEXT_PACKAGE);

        GLib.Environment.set_application_name(GETTEXT_PACKAGE);
        GLib.Environment.set_prgname(GETTEXT_PACKAGE);

        Gtk.init(ref argv);
        return new Application().run(argv);
    }
}