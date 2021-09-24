namespace Genesis {
    public enum PanelPosition {
        TOP,
        LEFT,
        RIGHT,
        BOTTOM
    }

    public enum Struts {
        LEFT,
        RIGHT,
        TOP,
        BOTTOM,
        LEFT_START,
        LEFT_END,
        RIGHT_START,
        RIGHT_END,
        TOP_START,
        TOP_END,
        BOTTOM_START,
        BOTTOM_END
    }

    [DBus(name = "com.expidus.GenesisPanelWindow")]
    public class PanelWindow : Gtk.ApplicationWindow {
        private Gtk.Widget? _widget = null;
        private string _monitor_name;
        private int _height = 15;
        private int _width = 0;
        private PanelPosition _position = PanelPosition.TOP;

        public string monitor_name {
            get {
                return this._monitor_name;
            }
            construct {
                this._monitor_name = value;
            }
        }

        [DBus(visible = false)]
        public unowned Gdk.Monitor? monitor {
            get {
                var disp = this.get_display();
                for (var i = 0; i < disp.get_n_monitors(); i++) {
                    unowned var mon = disp.get_monitor(i);
                    if (mon.get_model() == this.monitor_name) return mon;
                }

                int index = 0;
                if (int.try_parse(this.monitor_name, out index)) {
                    return disp.get_monitor(index);
                }
                return null;
            }
        }

        public int height {
            get {
                return this._height;
            }
            set {
                this._height = value;

                this.queue_resize();
                this.queue_draw();
                this.update_struts();
            }
        }

        public int width {
            get {
                return this._width;
            }
            set {
                this._width = value;

                this.queue_resize();
                this.queue_draw();
                this.update_struts();
            }
        }

        public PanelPosition position {
            get {
                return this._position;
            }
            set {
                this._position = value;

                this.queue_resize();
                this.queue_draw();
                this.update_struts();
            }
        }

        public class PanelWindow(PanelApplication application, string monitor_name) {
            Object(application: application, monitor_name: monitor_name);

            var mon = this.monitor;
            assert(mon != null);
            
            var rect = mon.geometry;

            this.type_hint = Gdk.WindowTypeHint.DOCK;
            this.decorated = false;
			this.skip_pager_hint = true;
			this.skip_taskbar_hint = true;
            this.resizable = false;
            this.show_all();
            this.move(rect.x, rect.y);

            this.notify["scale-factor"].connect(() => {
                this.queue_resize();
                this.queue_draw();
                this.update_struts();
            });

            try {
                application.conn.register_object("/com/expidus/GenesisPanel/window/%lu".printf(this.get_id()), this);
            } catch (GLib.Error e) {}

            this.update();
        }

        private double compute_dpi(int size) {
            var dpi = Genesis.get_monitor_dpi(this.monitor.geometry.width, this.monitor.geometry.height, this.monitor.width_mm, this.monitor.height_mm);
            return Genesis.compute_dpi(dpi, size, this.get_scale_factor() * 1.0);
        }

        private void update_struts() {
#if BUILD_X11
            var is_x11 = this.get_display() is Gdk.X11.Display;

            if (is_x11) {
                long struts[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                if (!this.get_realized()) return;

                switch (this.position) {
                    case PanelPosition.TOP:
                        struts[Struts.TOP] = ((int)this.compute_dpi(this.height) + this.monitor.geometry.y) * this.get_scale_factor();
                        struts[Struts.TOP_START] = this.monitor.geometry.x * this.get_scale_factor();
                        struts[Struts.TOP_END] = (this.monitor.geometry.x + this.monitor.geometry.width) * this.get_scale_factor() - 1;
                        break;
                    case PanelPosition.LEFT:
                        struts[Struts.LEFT] = (this.monitor.geometry.x + (int)this.compute_dpi(this.height)) * this.get_scale_factor();
                        struts[Struts.LEFT_START] = this.monitor.geometry.y * this.get_scale_factor();
                        struts[Struts.LEFT_END] = (this.monitor.geometry.y + this.monitor.geometry.height) * this.get_scale_factor() - 1;
                        break;
                    case PanelPosition.RIGHT:
                        struts[Struts.RIGHT] = (this.screen.get_width() + (this.width == 0 ? this.monitor.geometry.width : (int)this.compute_dpi(this.width))) - (this.monitor.geometry.x + this.monitor.geometry.width) * this.get_scale_factor();
                        struts[Struts.RIGHT_START] = this.monitor.geometry.y * this.get_scale_factor();
                        struts[Struts.RIGHT_END] = (this.monitor.geometry.y + this.monitor.geometry.height) * this.get_scale_factor() - 1;
                        break;
                    case PanelPosition.BOTTOM:
                    default:
                        struts[Struts.BOTTOM] = ((int)this.compute_dpi(this.height) + this.screen.get_height() - this.monitor.geometry.y - this.monitor.geometry.height) * this.get_scale_factor();
                        struts[Struts.BOTTOM_START] = this.monitor.geometry.x * this.get_scale_factor();
                        struts[Struts.BOTTOM_END] = (this.monitor.geometry.x + this.monitor.geometry.width) * this.get_scale_factor() - 1;
                        break;
                }

                var atom = Gdk.Atom.intern("_NET_WM_STRUT", false);
                Gdk.property_change(this.get_window(), atom, Gdk.Atom.intern("CARDINAL", false), 32, Gdk.PropMode.REPLACE, (uint8[])struts, 4);
                
                atom = Gdk.Atom.intern("_NET_WM_STRUT_PARTIAL", false);
                Gdk.property_change(this.get_window(), atom, Gdk.Atom.intern("CARDINAL", false), 32, Gdk.PropMode.REPLACE, (uint8[])struts, 12);
            } else
#endif
            {
                stdout.printf("This program was executed on a display backend that is not yet supported\n");
                GLib.Process.exit(1);
            }
        }

        public override void get_preferred_width(out int min_width, out int nat_width) {
			min_width = nat_width = this.width == 0 ? this.monitor.geometry.width : (int)this.compute_dpi(this.width);
		}

		public override void get_preferred_width_for_height(int height, out int min_width, out int nat_width) {
			this.get_preferred_width(out min_width, out nat_width);
		}

		public override void get_preferred_height(out int min_height, out int nat_height) {
			min_height = nat_height = (int)this.compute_dpi(this.height);
		}

		public override void get_preferred_height_for_width(int width, out int min_height, out int nat_height) {
			this.get_preferred_height(out min_height, out nat_height);
		}

        public override void map() {
            base.map();
            this.update_struts();
        }

        [DBus(visible = false)]
        public void update() {
            if (this._widget != null) this.remove(this._widget);

            var app = this.application as PanelApplication;
            assert(app != null);

            this._widget = app.component.get_default_widget(this.monitor_name);
            if (this._widget != null) this.add(this._widget);
        }
    }
}