namespace GenesisAbout {
    [GtkTemplate(ui = "/com/expidus/genesis/about/window.glade")]
    public class Window : Hdy.Window {
        [GtkChild(name = "header_bar")]
        private unowned Hdy.HeaderBar _header_bar;

        [GtkChild(name = "shell_version")]
        private unowned Gtk.Label _shell_version;

        [GtkChild(name = "os_version")]
        private unowned Gtk.Label _os_version;

        construct {
            this.set_resizable(false);
            this.set_gravity(Gdk.Gravity.CENTER);
            this.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
            this.set_default_size(600, 400);
            this.set_title(_("About Genesis Shell"));

            this._shell_version.label = _("Genesis Shell Version: %s").printf(Genesis.VERSION);
            this._os_version.label = _("OS: %s").printf(GLib.Environment.get_os_info("PRETTY_NAME"));
        }

        public Window() {
            Object();
        }

        public new void set_title(string str) {
            base.set_title(str);
            this._header_bar.set_title(str);
        }

        [GtkCallback(name = "open_website")]
        private void open_website() {
            var app_info = GLib.AppInfo.get_default_for_uri_scheme("https");
            if (app_info == null) app_info = GLib.AppInfo.get_default_for_uri_scheme("http");
            if (app_info == null) return;
            try {
                var list = new GLib.List<string>();
                list.append("https://expidusos.com");
                app_info.launch_uris(list, null);
            } catch (GLib.Error e) {
                stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
            }
        }
    }
}