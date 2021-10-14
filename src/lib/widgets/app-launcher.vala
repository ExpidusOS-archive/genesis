namespace Genesis {
    public class AppIconLauncher : Gtk.Bin {
        private string _app_id = "";
        private string _icon_name = "application-x-executable";
        private Gtk.IconSize _icon_size = Gtk.IconSize.BUTTON;
        private string _label = "Untitled Application";

        private Gtk.Button _btn;
        private Gtk.Box _box;
        private Gtk.Image _icon_widget;
        private Gtk.Label _label_widget;

        public string application_id {
            get {
                return this._app_id;
            }
            set construct {
                this._app_id = value;
            }
        }

        public string icon_name {
            get {
                return this._icon_name;
            }
            set construct {
                this._icon_name = value;
                if (this._icon_widget != null) this._icon_widget.icon_name = value;
            }
        }

        public Gtk.IconSize icon_size {
            get {
                return this._icon_size;
            }
            set construct {
                this._icon_size = value;
                if (this._icon_widget != null) this._icon_widget.icon_size = value;
            }
        }

        public string label {
            get {
                return this._label;
            }
            set construct {
                this._label = value;
                if (this._label_widget != null) this._label_widget.label = value;
            }
        }

        public AppIconLauncher() {
            this.init();
        }

        public AppIconLauncher.from_id(string app_id) throws GLib.Error {
            this._app_id = app_id;

            var app_info = new GLib.DesktopAppInfo(app_id);
            this._label = app_info.get_display_name();

            this.launch.connect(() => {
                try {
                    app_info.launch(null, null);
                } catch (GLib.Error e) {
                    stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                }
            });

            this.init();

            this._icon_widget.set_from_gicon(app_info.get_icon(), this._icon_size);
        }

        private void init() {
            this._btn = new Gtk.Button();
            this._box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this._label_widget = new Gtk.Label(this._label);
            this._icon_widget = new Gtk.Image.from_icon_name(this._icon_name, this._icon_size);

            this._box.pack_start(this._icon_widget, true, true, 0);
            this._box.pack_end(this._label_widget, true, false, 0);

            this._btn.add(this._box);
            this.add(this._btn);

            this._btn.clicked.connect(() => {
                this.launch();
            });
        }

        public signal void launch();
    }
}