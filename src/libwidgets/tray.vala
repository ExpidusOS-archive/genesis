[CCode (gir_namespace = "GenesisWidgets", gir_version = "1.0")]
namespace Genesis.X11 {
#if BUILD_X11
    private class TrayIcon : Gtk.Socket {
        private X.Window _xwin;
        private int _icon_size = 24;

        public int xwin {
            get {
                return (int)this._xwin;
            }
            construct {
                this._xwin = value;
            }
        }

        public int icon_size {
            get {
                return this._icon_size;
            }
            set construct {
                this._icon_size = value;
                if (this.get_realized()) {
                    this.queue_resize();
                    this.queue_draw();
                }
            }
        }

        construct {
            if (this.icon_size == 0) this.icon_size = 24;
            return_if_fail(this.xwin != 0);
        }

        public TrayIcon(X.Window xwin, int icon_size) {
            Object(xwin: (int)xwin, icon_size: icon_size);
        }

        public override void get_preferred_width(out int min_size, out int nat_size) {
            min_size = nat_size = this.icon_size;
        }

        public override void get_preferred_height(out int min_size, out int nat_size) {
            min_size = nat_size = this.icon_size;
        }

        public override void realize() {
            base.realize();
            this.set_size_request(this.icon_size, this.icon_size);
        }

        public void draw_on_tray(Gtk.Widget parent, Cairo.Context cr) {
            Gtk.Allocation alloc = {};
            this.get_allocation(out alloc);

            if (parent.get_has_window()) {
                Gtk.Allocation parent_alloc = {};
                this.get_parent().get_allocation(out parent_alloc);

                alloc.x = alloc.x - parent_alloc.x;
                alloc.y = alloc.y - parent_alloc.y;
            }

            cr.save();

            Gdk.cairo_set_source_window(cr, this.get_window(), alloc.x, alloc.y);
            cr.rectangle(alloc.x, alloc.y, alloc.width, alloc.height);
            cr.clip();
            cr.paint();
            cr.restore();
        }
    }

    public class Tray : Gtk.Box {
        private X.Atom _opcode;
        private X.Atom _data;
        private GLib.List<TrayIcon> _icons;
        private int _icon_size = 24;

        public int icon_size {
            get {
                return this._icon_size;
            }
            set construct {
                this._icon_size = value;
                foreach (var ti in this._icons) ti.icon_size = value;
            }
        }

        construct {
            this._icons = new GLib.List<TrayIcon>();
            if (this.icon_size == 0) this.icon_size = 24;
        }

        public Tray() {
            Object();
        }

        public Tray.with_icon_size(int icon_size) {
            Object(icon_size: icon_size);
        }

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

            this.set_xprops();

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

        public override bool draw(Cairo.Context cr) {
            this.@foreach((w) => {
                var ti = w as TrayIcon;
                if (ti == null) return;
                ti.draw_on_tray(this, cr);
            });
            return true;
        }

        private TrayIcon? find(X.Window xwin) {
            foreach (var ti in this._icons) {
                if (ti.xwin == xwin) return ti;
            }
            return null;
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
            var ti = this.find(win);

            if (ti == null) {
                ti = new TrayIcon(win, this.icon_size);
                ti.plug_removed.connect(() => {
                    this.undock(win);
                    return false;
                });

                this._icons.append(ti);
                this.pack_start(ti, false, false, 0);
                this.reorder_child(ti, 0);

                ti.add_id(win);
                ti.show_all();
            }
        }

        private void undock(X.Window win) {
            var ti = this.find(win);
            if (ti == null) return;

            this.remove(ti);
            this._icons.remove(ti);
        }

        private void set_xprops() {
            var disp = this.get_display() as Gdk.X11.Display;
            if (disp == null) return;

            var screen = disp.get_default_screen() as Gdk.X11.Screen;
            if (screen == null) return;

            var vis = screen.get_rgba_visual() as Gdk.X11.Visual;
            if (vis == null) vis = screen.get_system_visual() as Gdk.X11.Visual;
            if (vis == null) return;

            var xvis = vis.get_xvisual();

            var atom = Gdk.Atom.intern("_NET_SYSTEM_TRAY_VISUAL", false);
            ulong[] data = { xvis.get_visual_id() };
            Gdk.property_change(this.get_window(), atom, Gdk.Atom.intern("VISUALID", false), 32, Gdk.PropMode.REPLACE, (uint8[])data, 1);

            atom = Gdk.Atom.intern("_NET_SYSTEM_TRAY_ICON_SIZE", false);
            data[0] = this.icon_size;
            Gdk.property_change(this.get_window(), atom, Gdk.Atom.intern("CARDINAL", false), 32, Gdk.PropMode.REPLACE, (uint8[])data, 1);

            atom = Gdk.Atom.intern("_NET_SYSTEM_TRAY_ORIENTATION", false);
            var orient = this.get_orientation() == Gtk.Orientation.HORIZONTAL ? 1 : 0;
            data[0] = orient;
            Gdk.property_change(this.get_window(), atom, Gdk.Atom.intern("CARDINAL", false), 32, Gdk.PropMode.REPLACE, (uint8[])data, 1);
        }
    }
#else
    public class Tray : Gtk.Box {
        public int icon_size = 24;
    }
#endif
}