namespace Genesis {
    public class BaseAppGrid : Gtk.Bin {
        private Gtk.Grid _grid;
        private GLib.ListModel? _list = null;
        private ulong _list_changed;

        public int max_columns = 0;
        public int max_rows = 0;

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
            base.add(this._grid);

            this._grid.show();
        }

        public BaseAppGrid() {
        }

        private void use_list() {
            if (this._list != null) {
                this._list_changed = this._list.items_changed.connect((pos, rem, added) => {
                    foreach (var child in this._grid.get_children()) this._grid.remove(child);

                    var i = 0;
                    for (var y = 0; y < this.max_rows; y++) {
                        for (var x = 0; x < this.max_columns; x++) {
                            var item = this._list.get_item(i++) as Gtk.Widget;
                            if (item == null) continue;

                            this._grid.attach(item, x, y);
                        }
                    }
                });

                var i = 0;
                for (var y = 0; y < this.max_rows; y++) {
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
        private int _init_max_columns = 0;
        private int _init_max_rows = 0;
        private string[] _init_items = null;
        private GLib.ListStore _list;

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

            this._list = new GLib.ListStore(typeof (AppIconLauncher));
            this._app_grid.list_model = this._list;

            this.add(this._app_grid);
            this._app_grid.show();
        }

        public ListAppGrid() {
        }
    }

    public class SettingsAppGrid : Gtk.Bin {
        private string _schema_id;
        private string _schema_key;
        private ListAppGrid _app_grid;
        private int _init_max_columns = 0;
        private int _init_max_rows = 0;
        private GLib.Settings _settings;

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

            this._settings = new GLib.Settings(this.schema_id);
            this._settings.bind(this.schema_key, this._app_grid, "applications", GLib.SettingsBindFlags.GET | GLib.SettingsBindFlags.SET);

            this.add(this._app_grid);
            this._app_grid.show();
        }

        public SettingsAppGrid(string schema_id, string schema_key) {
            Object(schema_id: schema_id, schema_key: schema_key);
        }
    }
}