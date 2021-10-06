namespace Genesis {
    [DBus(name = "com.expidus.Notification")]
    public class NotificationWindow : Gtk.ApplicationWindow {
        private string _monitor_name;
        private Notification _notif;

        public string monitor_name {
            get {
                return this._monitor_name;
            }
            construct {
                this._monitor_name = value;
            }
        }

        public int monitor_index {
            get {
                var disp = this.get_display();
                for (var i = 0; i < disp.get_n_monitors(); i++) {
                    var mon = disp.get_monitor(i);
                    if (mon.geometry.equal(this.monitor.geometry)) return i;
                }
                return -1;
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

        construct { 
            var mon = this.monitor;
            assert(mon != null);
            
            var rect = mon.geometry;

            this.type_hint = Gdk.WindowTypeHint.NOTIFICATION;
            this.decorated = false;
			this.skip_pager_hint = true;
			this.skip_taskbar_hint = true;
            this.resizable = false;

            try {
                ((NotificationsApplication)this.application).conn.register_object("/com/expidus/GenesisNotifications/window/%lu".printf(this.get_id()), this);
            } catch (GLib.Error e) {}
        }

        public NotificationWindow(NotificationsApplication application, string monitor_name, Notification notif) {
            Object(application: application, monitor_name: monitor_name);

            this._notif = notif;
        }

        public signal void layout_changed();
    }
}