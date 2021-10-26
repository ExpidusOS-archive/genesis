namespace GenesisAbout {
    [GtkTemplate(ui = "/com/expidus/genesis/about/window.glade")]
    public class Window : Adw.ApplicationWindow {
        [GtkChild(name = "win_title")]
        private unowned Adw.WindowTitle _win_title;

        [GtkChild(name = "shell_version")]
        private unowned Gtk.Label _shell_version;

        [GtkChild(name = "website")]
        private unowned Gtk.Label _website;

        [GtkChild(name = "os")]
        private unowned Gtk.Label _os;

        [GtkChild(name = "windowing_system")]
        private unowned Gtk.Label _windowing_system;

        construct {
            this.set_resizable(false);
            this.set_default_size(600, 400);
            this.set_title(_("About Genesis Shell"));

            this._shell_version.label = Genesis.VERSION;
            this._website.set_markup("<a href=\"https://expidusos.com\">https://expidusos.com</a>");
            this._os.label = GLib.Environment.get_os_info("PRETTY_NAME");

#if BUILD_X11
            if (this.get_display() is Gdk.X11.Display) {
                var xdisp = (Gdk.X11.Display)this.get_display();
                this._windowing_system.label = _("X11 on %s").printf(xdisp.get_name());
            } else
#endif
#if BUILD_WAYLAND
            if (this.get_display() is Gdk.Wayland.Display) {
                var xdisp = (Gdk.Wayland.Display)this.get_display();
                this._windowing_system.label = _("Wayland on %s").printf(xdisp.get_name());
            } else
#endif
            {
                this._windowing_system.label = _("Unknown");
            }
        }

        public Window(Adw.Application application) {
            Object(application: application);
        }

        public new void set_title(string str) {
            base.set_title(str);
            this._win_title.set_title(str);
        }
    }
}