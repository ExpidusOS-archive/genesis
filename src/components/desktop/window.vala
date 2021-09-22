namespace Genesis {
    public class DesktopWindow : Gtk.ApplicationWindow {
        private Gtk.Widget? _widget = null;
        private string _monitor_name;

        public string monitor_name {
            get {
                return this._monitor_name;
            }
            construct {
                this._monitor_name = value;
            }
        }

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

        public class DesktopWindow(DesktopApplication application, string monitor_name) {
            Object(application: application, monitor_name: monitor_name);

            var mon = this.monitor;
            assert(mon != null);
            
            var rect = mon.geometry;

            this.type_hint = Gdk.WindowTypeHint.DESKTOP;
            this.decorated = false;
			this.skip_pager_hint = true;
			this.skip_taskbar_hint = true;
            this.resizable = false;
            this.show_all();
            this.move(rect.x, rect.y);

            this.update();
        }

        public override void get_preferred_width(out int min_width, out int nat_width) {
            min_width = nat_width = this.monitor.geometry.width;
        }

        public override void get_preferred_width_for_height(int height, out int min_width, out int nat_width) {
			this.get_preferred_width(out min_width, out nat_width);
		}

        public override void get_preferred_height(out int min_height, out int nat_height) {
            min_height = nat_height = this.monitor.geometry.height;
        }

        public override void get_preferred_height_for_width(int width, out int min_height, out int nat_height) {
			this.get_preferred_height(out min_height, out nat_height);
		}

        public void update() {
            if (this._widget != null) this.remove(this._widget);

            var app = this.application as DesktopApplication;
            assert(app != null);

            this._widget = app.component.get_default_widget(this.monitor_name);
            if (this._widget != null) this.add(this._widget);
        }
    }
}