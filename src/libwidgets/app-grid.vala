namespace Genesis {
    public class BaseAppGrid : Gtk.Bin {
        private Gtk.Grid _grid;
        private GLib.ListModel? _list = null;
        private int _init_column_spacing = 6;
        private ulong _list_changed;

        public int max_columns = 1;
        public int max_rows = 0;

        public int column_spacing {
            get {
                if (this._grid != null) return this._grid.column_spacing;
                return this._init_column_spacing;
            }
            set construct {
                if (this._grid != null) this._grid.column_spacing = value;
                else this._init_column_spacing = value;
            }
        }

        public GLib.ListModel? list_model {
            get {
                return this._list;
            }
            set {
                if (value == null) {
                    this.unuse_list();
                } else if (this._list == null && value != null) {
                    this._list = value;
                    this.use_list();
                } else {
                    this.unuse_list();
                    this._list = value;
                    this.use_list();
                }
            }
        }

        construct {
            this._grid = new Gtk.Grid();
            this._grid.column_spacing = this._init_column_spacing;
            base.add(this._grid);

            this.bind_property("margin-top", this._grid, "margin-top", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-bottom", this._grid, "margin-bottom", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-start", this._grid, "margin-start", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-end", this._grid, "margin-end", GLib.BindingFlags.SYNC_CREATE);

            this._grid.show();
        }

        public BaseAppGrid() {
        }

        private void use_list() {
            if (this._list != null) {
                this._list_changed = this._list.items_changed.connect((pos, rem, added) => {
                    foreach (var child in this._grid.get_children()) this._grid.remove(child);

                    var max_columns = this.max_columns == 0 ? 1 : this.max_columns;
                    var max_rows = this.max_rows == 0 ? (int)(this._list.get_n_items() / max_columns) : this.max_rows;

                    var i = 0;
                    for (var y = 0; y < max_rows; y++) {
                        for (var x = 0; x < this.max_columns; x++) {
                            var item = this._list.get_item(i++) as Gtk.Widget;
                            if (item == null) continue;

                            this._grid.attach(item, x, y);
                        }
                    }
                });

                var max_columns = this.max_columns == 0 ? 1 : this.max_columns;
                var max_rows = this.max_rows == 0 ? (int)(this._list.get_n_items() / max_columns) : this.max_rows;
                var i = 0;
                for (var y = 0; y < max_rows; y++) {
                    for (var x = 0; x < this.max_columns; x++) {
                        var item = this._list.get_item(i++) as Gtk.Widget;
                        if (item == null) continue;

                        this._grid.attach(item, x, y);
                    }
                }
            }
        }

        private void unuse_list() {
            if (this._list != null) {
                this._list.disconnect(this._list_changed);
                this._list = null;

                foreach (var child in this._grid.get_children()) this._grid.remove(child);
            }
        }

        public override void add(Gtk.Widget widget) {
            this._grid.add(widget);
        }

        public override void remove(Gtk.Widget widget) {
            this._grid.remove(widget);
        }
    }

    public class ListAppGrid : Gtk.Bin {
        private BaseAppGrid _app_grid;
        private int _init_max_columns = 1;
        private int _init_max_rows = 0;
        private int _init_column_spacing = 6;
        private string[] _init_items = null;
        private GLib.ListStore _list;

        public int column_spacing {
            get {
                if (this._app_grid != null) return this._app_grid.column_spacing;
                return this._init_column_spacing;
            }
            set construct {
                if (this._app_grid != null) this._app_grid.column_spacing = value;
                else this._init_column_spacing = value;
            }
        }

        public int max_columns {
            get {
                if (this._app_grid == null) return this._init_max_columns;
                return this._app_grid.max_columns;
            }
            set construct {
                if (this._app_grid == null) {
                    this._init_max_columns = value;
                } else {
                    this._app_grid.max_columns = value;
                }
            }
        }

        public int max_rows {
            get {
                if (this._app_grid == null) return this._init_max_rows;
                return this._app_grid.max_rows;
            }
            set construct {
                if (this._app_grid == null) {
                    this._init_max_rows = value;
                } else {
                    this._app_grid.max_rows = value;
                }
            }
        }

        public string[] applications {
            owned get {
                string[] val = {};
                for (var i = 0; i < this._list.get_n_items(); i++) {
                    var item = this._list.get_item(i) as AppIconLauncher;
                    val += item.application_id;
                }
                return val;
            }
            set construct {
                this._init_items = value;
                if (this._list != null) {
                    this._list.remove_all();

                    foreach (var app_id in this._init_items) {
                        try {
                            var item = new AppIconLauncher.from_id(app_id);
                            this._list.append(item);
                            item.show_all();
                        } catch (GLib.Error e) {}
                    }
                }
            }
        }

        construct {
            this._app_grid = new BaseAppGrid();
            this._app_grid.max_columns = this._init_max_columns;
            this._app_grid.max_rows = this._init_max_rows;
            this._app_grid.column_spacing = this._init_column_spacing;

            this.bind_property("margin-top", this._app_grid, "margin-top", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-bottom", this._app_grid, "margin-bottom", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-start", this._app_grid, "margin-start", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-end", this._app_grid, "margin-end", GLib.BindingFlags.SYNC_CREATE);

            this._list = new GLib.ListStore(typeof (AppIconLauncher));
            this._app_grid.list_model = this._list;

            this.add(this._app_grid);
            this._app_grid.show();
        }

        public ListAppGrid() {
            Object();
        }
    }

    public class SettingsAppGrid : Gtk.Bin {
        private string _schema_id;
        private string _schema_key;
        private ListAppGrid _app_grid;
        private int _init_max_columns = 1;
        private int _init_max_rows = 0;
        private int _init_column_spacing = 6;
        private GLib.Settings _settings;

        public int column_spacing {
            get {
                if (this._app_grid != null) return this._app_grid.column_spacing;
                return this._init_column_spacing;
            }
            set construct {
                if (this._app_grid != null) this._app_grid.column_spacing = value;
                else this._init_column_spacing = value;
            }
        }

        public int max_columns {
            get {
                if (this._app_grid == null) return this._init_max_columns;
                return this._app_grid.max_columns;
            }
            set construct {
                if (this._app_grid == null) {
                    this._init_max_columns = value;
                } else {
                    this._app_grid.max_columns = value;
                }
            }
        }

        public int max_rows {
            get {
                if (this._app_grid == null) return this._init_max_rows;
                return this._app_grid.max_rows;
            }
            set construct {
                if (this._app_grid == null) {
                    this._init_max_rows = value;
                } else {
                    this._app_grid.max_rows = value;
                }
            }
        }

        public string schema_id {
            get {
                return this._schema_id;
            }
            construct {
                this._schema_id = value;
            }
        }

        public string schema_key {
            get {
                return this._schema_key;
            }
            construct {
                this._schema_key = value;
            }
        }

        construct {
            this._app_grid = new ListAppGrid();
            this._app_grid.max_columns = this._init_max_columns;
            this._app_grid.max_rows = this._init_max_rows;
            this._app_grid.column_spacing = this._init_column_spacing;

            this.bind_property("margin-top", this._app_grid, "margin-top", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-bottom", this._app_grid, "margin-bottom", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-start", this._app_grid, "margin-start", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-end", this._app_grid, "margin-end", GLib.BindingFlags.SYNC_CREATE);

            this._settings = new GLib.Settings(this.schema_id);
            this._settings.bind(this.schema_key, this._app_grid, "applications", GLib.SettingsBindFlags.GET | GLib.SettingsBindFlags.SET);

            this.add(this._app_grid);
            this._app_grid.show();
        }

        public SettingsAppGrid(string schema_id, string schema_key) {
            Object(schema_id: schema_id, schema_key: schema_key);
        }
    }

    public class AppLauncherGrid : Gtk.Bin {
        private BaseAppGrid _app_grid;
        private int _init_max_columns = 1;
        private int _init_max_rows = 0;
        private int _init_column_spacing = 6;
        private GLib.ListStore _list;
        private ulong _changed;
        private GLib.AppInfoMonitor _monitor;

        public int column_spacing {
            get {
                if (this._app_grid != null) return this._app_grid.column_spacing;
                return this._init_column_spacing;
            }
            set construct {
                if (this._app_grid != null) this._app_grid.column_spacing = value;
                else this._init_column_spacing = value;
            }
        }

        public int max_columns {
            get {
                if (this._app_grid == null) return this._init_max_columns;
                return this._app_grid.max_columns;
            }
            set construct {
                if (this._app_grid == null) {
                    this._init_max_columns = value;
                } else {
                    this._app_grid.max_columns = value;
                }
            }
        }

        public int max_rows {
            get {
                if (this._app_grid == null) return this._init_max_rows;
                return this._app_grid.max_rows;
            }
            set construct {
                if (this._app_grid == null) {
                    this._init_max_rows = value;
                } else {
                    this._app_grid.max_rows = value;
                }
            }
        }

        construct {
            this._app_grid = new BaseAppGrid();
            this._app_grid.max_columns = this._init_max_columns;
            this._app_grid.max_rows = this._init_max_rows;
            this._app_grid.column_spacing = this._init_column_spacing;

            this.bind_property("margin-top", this._app_grid, "margin-top", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-bottom", this._app_grid, "margin-bottom", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-start", this._app_grid, "margin-start", GLib.BindingFlags.SYNC_CREATE);
            this.bind_property("margin-end", this._app_grid, "margin-end", GLib.BindingFlags.SYNC_CREATE);

            this._list = new GLib.ListStore(typeof (AppIconLauncher));
            this._app_grid.list_model = this._list;

            this._monitor = GLib.AppInfoMonitor.@get();
            this._changed = this._monitor.changed.connect(() => {
                this.update();
            });

            this.update();

            this.add(this._app_grid);
            this._app_grid.show();
        }

        public AppLauncherGrid() {
            Object();
        }

        ~AppLauncherGrid() {
            this._monitor.disconnect(this._changed);
        }

        private void update() {
            this._list.remove_all();

            var apps = GLib.AppInfo.get_all();
            foreach (var app in apps) {
                if (!app.should_show()) continue;

                try {
                   var item = new AppIconLauncher.from_id(app.get_id());
                   this._list.append(item);
                   item.show_all();
                } catch (GLib.Error e) {}
            }
        }
    }
}