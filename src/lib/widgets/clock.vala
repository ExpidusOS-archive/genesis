namespace Genesis {
    public class BaseClock : Gtk.Box {
        private string _fmt = "%r";
        private uint _interval = 1;
        private uint _timeout = 0;

        public string format {
            get {
                return this._fmt;
            }
            set construct {
                this._fmt = value;
            }
        }

        public uint interval {
            get {
                return this._interval;
            }
            set construct {
                this._interval = value;
                if (this._timeout != 0) {
                    GLib.Source.remove(this._timeout);
                    this._timeout = 0;
                    this.init_timeout();
                }
            }
        }

        construct {
            this.init_timeout();
        }

        public BaseClock() {
            Object();
        }

        ~BaseClock() {
            GLib.Source.remove(this._timeout);
            this._timeout = 0;
        }

        protected void do_update() {
            if (this.format == null) this.format = "%r";
            var dt = new GLib.DateTime.now_local();
            this.time_sync(dt.format(this.format));
        }

        protected void init_timeout() {
            if (this._timeout == 0) {
                if (this.interval == 0) this.interval = 1;

                this._timeout = GLib.Timeout.add_seconds(this.interval, () => {
                    this.do_update();
                    return this._timeout != 0;
                });
                this.do_update();
            }
        }

        public signal void time_sync(string time);
    }

    public class SimpleClock : BaseClock {
        private Gtk.Label _label;

        construct {
            this._label = new Gtk.Label(null);
            this.time_sync.connect((time) => {
                this._label.label = time;
            });
            this.do_update();
            this.append(this._label);
            this._label.show();
        }

        public SimpleClock() {
            Object();
        }
    }
}