[CCode (gir_namespace = "GenesisWidgets", gir_version = "1.0")]
namespace Genesis.X11 {
#if BUILD_X11
    public class Tray : Gtk.Box {
        private X.Atom _opcode;
        private X.Atom _data;

        public override void map() {
            base.map();

            var disp = this.get_display() as Gdk.X11.Display;
            assert(disp != null);

            var screen = disp.get_default_screen() as Gdk.X11.Screen;
            assert(screen != null);

            var win = (this.get_window() == null ? this.get_window() : this.get_toplevel().get_window()) as Gdk.X11.Window;
            assert(win != null);

            var root_win = screen.get_root_window() as Gdk.X11.Window;
            assert(root_win != null);

            var atom = Gdk.Atom.intern("_NET_SYSTEM_TRAY_S%d".printf(screen.get_screen_number()), false);
            var timestamp = Gdk.X11.get_server_time(win);
            return_if_fail(Gdk.Selection.owner_set_for_display(disp, win, atom, timestamp, true));

            X.ClientMessageEvent ev = {
                type: X.EventType.ClientMessage,
                window: root_win.get_xid()
            };

            ev.message_type = Gdk.X11.get_xatom_by_name_for_display(disp, "MANAGER");
            ev.format = 32;
            ev.l[0] = timestamp; 
            ev.l[1] = (long)Gdk.X11.atom_to_xatom(atom);
            ev.l[2] = (long)win.get_xid();
            ev.l[3] = 0;
            ev.l[4] = 0;

            this._opcode = Gdk.X11.get_xatom_by_name_for_display(disp, "_NET_SYSTEM_TRAY_OPCODE");
            this._data = Gdk.X11.get_xatom_by_name_for_display(disp, "_NET_SYSTEM_TRAY_MESSAGE_DATA");

            win.add_filter(this.filter);
        }

        public override void unmap() {
            var disp = this.get_display() as Gdk.X11.Display;
            assert(disp != null);

            var screen = disp.get_default_screen() as Gdk.X11.Screen;
            assert(screen != null);

            var win = (this.get_window() == null ? this.get_window() : this.get_toplevel().get_window()) as Gdk.X11.Window;
            assert(win != null);

            var atom = Gdk.Atom.intern("_NET_SYSTEM_TRAY_S%d".printf(screen.get_screen_number()), false);
            Gdk.Selection.owner_set_for_display(disp, null, atom, Gdk.X11.get_server_time(win), true);

            win.remove_filter(this.filter);
            base.unmap();
        }

        private Gdk.FilterReturn filter(Gdk.XEvent _xev, Gdk.Event ev) {
            var xev = (X.Event*)_xev;

            if (xev->type == X.EventType.ClientMessage) {
                var xclient = (X.ClientMessageEvent*)xev;

                if (xclient->message_type == this._opcode) {
                    switch (xclient.l[0]) {
                        case 0: // request
                            this.dock(xclient);
                            break;
                        case 1: // begin
                            break;
                        case 2: // cancel
                            break;
                    }
                } else if (xclient->message_type == this._data) {
                    return Gdk.FilterReturn.REMOVE;
                }
            }
            return Gdk.FilterReturn.CONTINUE;
        }

        private void dock(X.ClientMessageEvent* xclient) {
            X.Window win = (X.Window)xclient.l[2];
        }
    }
#else
    public class Tray : Gtk.Box {
    }
#endif
}