namespace Genesis {
    public class GlobalMenu : Gtk.MenuBar {
        private Gdk.Window? _active_win;
        private GLib.DBusMenuModel? _app_menu;
        private GLib.DBusActionGroup? _app_group;
        private GLib.DBusActionGroup? _win_group;
        private string? _app_id;
        private GLib.DBusConnection _conn;
        private uint _timeout = 0;

        construct {
            this._timeout = 0;
            try {
                this._conn = GLib.Bus.get_sync(GLib.BusType.SESSION, null);
            } catch (GLib.Error e) {
                stderr.printf("Failed to connect to DBus %s (%d): %s\n", e.domain.to_string(), e.code, e.message);
            }
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
            if (this.get_display() is Gdk.X11.Display) {
                var xdisp = this.get_display() as Gdk.X11.Display;
                Gdk.Atom real_type;
                int real_fmt;
                uint8[] data;
                if (Gdk.property_get(xdisp.get_default_screen().get_root_window(), Gdk.Atom.intern("_NET_ACTIVE_WINDOW", false), Gdk.Atom.intern("WINDOW", false), 0, 32, 0, out real_type, out real_fmt, out data)) {
                    X.Window[] xwin = (X.Window[])data;
                    if (xwin[0] > 0) {
                        this._active_win = new Gdk.X11.Window.foreign_for_display(xdisp, xwin[0]);

                        // TODO: figure out why this doesn't show the menu
                        /*if (Gdk.property_get(this._active_win, Gdk.Atom.intern("WM_TRANSIENT_FOR", false), Gdk.Atom.intern("WINDOW", false), 0, 32, 0, out real_type, out real_fmt, out data)) {
                            xwin = (X.Window[])data;
                            if (xwin[0] > 0) {
                                this._active_win = new Gdk.X11.Window.foreign_for_display(xdisp, xwin[0]);
                            }
                        }*/
                    }
                }
            } else
#endif
#if BUILD_WAYLAND
            if (this.get_display() is Gdk.Wayland.Display) {
                // TODO
            } else
#endif
            {
                stderr.printf("Failed to find a compatible display backend\n");
            }

            if (this._active_win != old_value) this.update_menu();
        }

        private void update_menu() {
            this._app_menu = null;
            this._app_id = null;

            if (this._active_win != null) {
#if BUILD_X11
                if (this.get_display() is Gdk.X11.Display) {
                    Gdk.Atom real_type;
                    int real_fmt;
                    uint8[] data;
                    string? menu_obj_path = null;
                    string? app_obj_path = null;
                    string? win_obj_path = null;

                    if (Gdk.property_get(this._active_win, Gdk.Atom.intern("_GTK_MENUBAR_OBJECT_PATH", false), Gdk.Atom.intern("UTF8_STRING", false), 0, 128, 0, out real_type, out real_fmt, out data)) {
                        var sb = new GLib.StringBuilder.sized(data.length);
                        foreach (var c in data) sb.append_c((char)c);
                        menu_obj_path = sb.str;
                    }

                    if (Gdk.property_get(this._active_win, Gdk.Atom.intern("_GTK_APPLICATION_OBJECT_PATH", false), Gdk.Atom.intern("UTF8_STRING", false), 0, 128, 0, out real_type, out real_fmt, out data)) {
                        var sb = new GLib.StringBuilder.sized(data.length);
                        foreach (var c in data) sb.append_c((char)c);
                        app_obj_path = sb.str;
                    }

                    if (Gdk.property_get(this._active_win, Gdk.Atom.intern("_GTK_WINDOW_OBJECT_PATH", false), Gdk.Atom.intern("UTF8_STRING", false), 0, 128, 0, out real_type, out real_fmt, out data)) {
                        var sb = new GLib.StringBuilder.sized(data.length);
                        foreach (var c in data) sb.append_c((char)c);
                        win_obj_path = sb.str;
                    }

                    if (Gdk.property_get(this._active_win, Gdk.Atom.intern("_GTK_APPLICATION_ID", false), Gdk.Atom.intern("UTF8_STRING", false), 0, 128, 0, out real_type, out real_fmt, out data)) {
                        var sb = new GLib.StringBuilder.sized(data.length);
                        foreach (var c in data) sb.append_c((char)c);
                        this._app_id = sb.str;
                    } else if (Gdk.property_get(this._active_win, Gdk.Atom.intern("_GTK_UNIQUE_BUS_NAME", false), Gdk.Atom.intern("UTF8_STRING", false), 0, 128, 0, out real_type, out real_fmt, out data)) {
                        var sb = new GLib.StringBuilder.sized(data.length);
                        foreach (var c in data) sb.append_c((char)c);
                        this._app_id = sb.str;
                    }

                    if (this._app_id != null && menu_obj_path != null && this._conn != null) {
                        this._app_menu = GLib.DBusMenuModel.@get(this._conn, this._app_id, menu_obj_path);

                        if (app_obj_path != null) {
                            this._app_group = GLib.DBusActionGroup.@get(this._conn, this._app_id, app_obj_path);
                            this.insert_action_group("app", this._app_group);
                        }
                        if (win_obj_path != null) {
                            this._win_group = GLib.DBusActionGroup.@get(this._conn, this._app_id, win_obj_path);
                            this.insert_action_group("win", this._win_group);
                        }
                    }
                } else
#endif
#if BUILD_WAYLAND
                if (this.get_display() is Gdk.Wayland.Display) {
                    // TODO
                } else
#endif
                {
                    stderr.printf("Failed to find a compatible display backend\n");
                }
            }

            this.@foreach((w) => this.remove(w));
            
            if (this._app_menu != null) {
                this.bind_model(this._app_menu, null, true);
            }
        }
    }
}