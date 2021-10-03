namespace Genesis {
    public class GlobalMenu : Gtk.MenuBar {
        private Gdk.Window? _active_win;
        private Gtk.Menu _default_menu;
        private DbusmenuGtk.Menu? _app_menu;
        private uint _timeout = 0;

        construct {
            this._default_menu = new Gtk.Menu();
            this._timeout = 0;
        }

        public GlobalMenu() {
            Object();
        }

        ~GlobalMenu() { 
            if (this._timeout > 0) GLib.Source.remove(this._timeout);
        }

        public override void realize() {
            base.realize();
            this.update_active();
            this._timeout = GLib.Timeout.add_seconds(1, () => {
                this.update_active();
                return this._timeout != 0;
            });
        }

        public override void unrealize() {
            base.unrealize();
            if (this._timeout > 0) {
                GLib.Source.remove(this._timeout);
                this._timeout = 0;
            }
        }

        private void update_active() {
            var old_value = this._active_win;
            this._active_win = null;
#if BUILD_X11
            var is_x11 = this.get_display() is Gdk.X11.Display;
            if (is_x11) {
                var xdisp = this.get_display() as Gdk.X11.Display;
                Gdk.Atom real_type;
                int real_fmt;
                uint8[] data;
                if (Gdk.property_get(xdisp.get_default_screen().get_root_window(), Gdk.Atom.intern("_NET_ACTIVE_WINDOW", false), Gdk.Atom.intern("WINDOW", false), 0, 32, 0, out real_type, out real_fmt, out data)) {
                    X.Window[] xwin = (X.Window[])data;
                    if (data[0] > 0) this._active_win = new Gdk.X11.Window.foreign_for_display(xdisp, xwin[0]);
                }
            }
#endif

            if (this._active_win != old_value) this.update_menu();
        }

        private void update_menu() {
            this._app_menu = null;
            if (this._active_win != null) {
#if BUILD_X11
                var is_x11 = this.get_display() is Gdk.X11.Display;
                if (is_x11) {
                    Gdk.Atom real_type;
                    int real_fmt;
                    uint8[] data;
                    string? obj_path = null;
                    string? app_id = null;
                    if (Gdk.property_get(this._active_win, Gdk.Atom.intern("_GTK_MENUBAR_OBJECT_PATH", false), Gdk.Atom.intern("UTF8_STRING", false), 0, 32, 0, out real_type, out real_fmt, out data)) {
                        obj_path = @"$((string) data)";
                    }

                    if (Gdk.property_get(this._active_win, Gdk.Atom.intern("_GTK_APPLICATION_ID", false), Gdk.Atom.intern("UTF8_STRING", false), 0, 32, 0, out real_type, out real_fmt, out data)) {
                        app_id = @"$((string) data)";
                    } else if (Gdk.property_get(this._active_win, Gdk.Atom.intern("_GTK_UNIQUE_BUS_NAME", false), Gdk.Atom.intern("UTF8_STRING", false), 0, 32, 0, out real_type, out real_fmt, out data)) {
                        app_id = @"$((string) data)";
                    }

                    if (app_id != null && obj_path != null) this._app_menu = new DbusmenuGtk.Menu(app_id, obj_path);
                }
#endif
            }

            this.@foreach((w) => this.remove(w));
            
            if (this._active_win == null || this._app_menu == null) {
                this._default_menu.@foreach((w) => this.add(w));
            } else if (this._app_menu != null) {
                this._app_menu.@foreach((w) => this.add(w));
            }
        }
    }
}