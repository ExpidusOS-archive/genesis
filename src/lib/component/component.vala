namespace Genesis {
    private struct ComponentEvent {
        public Component self;
        public string name;
    }

    [DBus(name = "com.expidus.GenesisComponent")]
    public class Component : GLib.Object {
        private string _default_id = "";
        private bool _should_build_ui = true;
        private GLib.HashTable<string, string> _layouts = new GLib.HashTable<string, string>(GLib.str_hash, GLib.str_equal);
        private GLib.HashTable<string, Gtk.Builder> _builders = new GLib.HashTable<string, Gtk.Builder>(GLib.str_hash, GLib.str_equal);
        private GLib.HashTable<string, string?> _monitors = new GLib.HashTable<string, string?>(GLib.str_hash, GLib.str_equal);
        private GLib.HashTable<string, string> _exported_objs = new GLib.HashTable<string, string>(GLib.str_hash, GLib.str_equal);

        [DBus(visible = false)]
        public bool should_build_ui {
            get {
                return this._should_build_ui;
            }
            set {
                this._should_build_ui = value;
                foreach (var monitor in this._monitors.get_keys()) this.layout_changed(monitor);
            }
        }

        [DBus(name = "DefaultID")]
        public string default_id {
            get {
                return this._default_id;
            }
            set {
                this._default_id = value;
            }
        }

        [DBus(visible = false)]
        public string? get_layout(string monitor) {
            var misd = this._monitors.get(monitor);
            if (misd == null) return null;

            return this._layouts.get(misd);
        }

        [DBus(visible = false)]
        public unowned Gtk.Widget? get_default_widget(string monitor) {
            if (this._default_id == null) return null;

            var builder = this._builders.get(monitor);
            if (builder == null) return null;

            var path = this._default_id.split("/");
            var root = path[0];
            path = path[1:path.length];

            return this.tree(builder.get_object(root) as Gtk.Widget, path);
        }

        [DBus(visible = false)]
        public Gtk.Widget[]? get_widgets(string monitor) {
            var misd = this._monitors.get(monitor);
            if (misd == null) return null;

            if (this._exported_objs.contains(misd)) {
                var builder = this._builders.get(monitor);
                if (builder == null) return null;

                var ids = this._exported_objs.get(misd).split(",");

                Gtk.Widget[] widgets = {};
                foreach (var id in ids) {
                    var path = id.split("/");
                    var root = path[0];
                    path = path[1:path.length];

                    widgets += this.tree(builder.get_object(root) as Gtk.Widget, path);
                }
                return widgets;
            }
            return { this.get_default_widget(monitor) };
        }

        private unowned Gtk.Widget? tree(Gtk.Widget? parent, string[] path) {
            if (parent == null) return null;
            if (path.length == 0) return parent;

            var curr = path[0];
            var next = path[1:path.length];

            var children = parent.observe_children();
            if (children == null) return null;
            for (var i = 0; i < children.get_n_items(); i++) {
                var child = children.get_item(i) as Gtk.Widget;
                if (child == null) continue;

                if (child.name == curr) {
                    return this.tree(child, next);
                }
            }
            return null;
        }

        [DBus(name = "ApplyLayout")]
        public void apply_layout(string monitor, string misd) throws GLib.Error {
            if (misd.length == 0) {
                this._monitors.remove(monitor);
                this.monitor_changed(monitor, false);
            } else {
                this._monitors.set(monitor, misd);
                this.monitor_changed(monitor, true);
            }
        }

        [DBus(name = "DefineLayout")]
        public void define_layout(string misd, string layout) throws GLib.Error {
            this._layouts.set(misd, layout);
        }

        [DBus(name = "LoadLayout")]
        public void load_layout(string monitor) throws GLib.Error {
            var misd = this._monitors.get(monitor);
            if (misd == null) return;

            var layout = this._layouts.get(misd);
            if (layout == null) return;

            if (this.should_build_ui) {
                var builder = new Gtk.Builder();
                builder.add_from_string(layout, layout.length);
                this._builders.set(monitor, builder);
            }

            this.layout_changed(monitor);
        }

        [DBus(name = "Shutdown")]
        public void shutdown() throws GLib.Error {
            this.killed();
        }

        [DBus(name = "ExportObjects")]
        public void export_objects(string misd, string[] objs) throws GLib.Error {
            this._exported_objs.set(misd, string.joinv(",", objs));
        }

        [DBus(name = "WidgetSimpleEvent")]
        public signal void widget_simple_event(string path, string name);

        [DBus(visible = false)]
        public signal void layout_changed(string monitor);

        [DBus(visible = false)]
        public signal void monitor_changed(string monitor, bool added);

        [DBus(visible = false)]
        public signal void killed();
    }

    private void handler_widget_simple_event(Gtk.Widget widget, ComponentEvent* ev) {
        ev->self.widget_simple_event(get_widget_path(widget), ev->name);
    }

    private string get_widget_path(Gtk.Widget child) {
        var path = child.name;
        var parent = child.get_parent();
        if (parent != null) path += "/" + get_widget_path(parent);
        return path;
    }
}