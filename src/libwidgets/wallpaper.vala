namespace Genesis {
    public class DesktopWallpaper : Gtk.Bin {
        private Gdk.Pixbuf? _img = null;
        private bool _override = false;
        private string? _path = null;
        private bool _is_drawing = false;
        private GLib.Settings _settings;

        public bool @override {
            get {
                return this._override;
            }
            set {
                this._override = value;
            }
        }

        public string? img_path {
            get {
                return this._path;
            }
            set {
                this._path = value;
                this._img = null;
                try {
                    this.update();
                } catch (GLib.Error e) {
                    stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                }
            }
        }

        public DesktopWallpaper() {
            this._img = null;

            this.map_event.connect((ev) => {
                try {
                    this._img = null;
                    this.update();
                } catch (GLib.Error e) {
                    stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                }
                return false;
            });

            try {
                this.update();
            } catch (GLib.Error e) {
                stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
            }
        }

        private void init() {
            if (this._settings == null) {
                this._settings = new GLib.Settings("com.expidus.genesis.desktop");
                this._settings.changed["wallpaper"].connect(() => {
                    try {
                        this._img = null;
                        this.update();
                    } catch (GLib.Error e) {
                        stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                    }
                });
            }
        }

        private void update() throws GLib.Error {
            if (this._img == null) {
                Gtk.Allocation alloc;
                int baseline;
                this.get_allocated_size(out alloc, out baseline);

                var p = this.img_path;
                if (!this.@override || this.img_path != null) {
                    this.init();
                    p = this._settings.get_string("wallpaper");
                }

                this._img = new Gdk.Pixbuf.from_file_at_size(p, alloc.width, alloc.height);
            }

            if (!this._is_drawing) this.queue_draw();
        }

        public override bool draw(Cairo.Context cr) {
            this._is_drawing = true;
            var ret = base.draw(cr);

            try {
                this.update();
            } catch (GLib.Error e) {
                stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
            }

            if (this._img != null) {
                Gdk.cairo_set_source_pixbuf(cr, this._img, 0, 0);
                cr.paint();
            }

            this._is_drawing = true;
            return ret;
        }
    }
}