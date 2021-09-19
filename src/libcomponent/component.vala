namespace Genesis {
    private struct ComponentEvent {
        public Component self;
        public string name;
    }

    [DBus(name = "com.genesis.Component")]
    public class Component : GLib.Object {
        private Gtk.Builder? _builder;
        private string? _default_id = null;

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
        public unowned Gtk.Widget? default_widget {
            get {
                if (this._default_id == null) return null;
                if (this._builder == null) return null;
                var path = this._default_id.split("/");
                var root = path[0];
                path = path[1:path.length];
                return this.tree(this._builder.get_object(root) as Gtk.Widget, path);
            }
        }

        private unowned Gtk.Widget? tree(Gtk.Widget parent, string[] path) {
            if (path.length == 0) return parent;

            var curr = path[0];
            var next = path[1:path.length];

            var container = parent as Gtk.Container;
            if (container == null) return null;
            foreach (var child in container.get_children()) {
                if (child.name == curr) {
                    return this.tree(child, next);
                }
            }
            return null;
        }

        [DBus(name = "LoadLayout")]
        public void load_layout(string layout) throws GLib.Error {
            this._builder = new Gtk.Builder();
            this._builder.connect_signals_full((builder, obj, sig_name, handler_name, conn_obj, flags) => {
                var widget = obj as Gtk.Widget;
                if (widget != null) {
                    ComponentEvent ev = {
                        self: this,
                        name: sig_name
                    };

                    switch (handler_name) {
                        case "widget_simple_event":
                            GLib.Signal.connect(obj, sig_name, (GLib.Callback)handler_widget_simple_event, &ev);
                            break;
                    }
                }
            });
            this._builder.add_from_string(layout, layout.length);
        }

        [DBus(name = "WidgetClick")]
        public signal void widget_simple_event(string path, string name);
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