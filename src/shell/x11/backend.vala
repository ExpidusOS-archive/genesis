namespace Genesis.X11 {
    public class Backend : GLib.Object, Genesis.ShellBackend {
        private Genesis.Shell _shell;

        private Xcb.Connection _conn;
        private int _def_screen;
        private Xcb.RandR.Connection _randr;

        private GLib.HashTable<string, Monitor> _monitors;
        private GLib.HashTable<string, Xcb.Atom?> _atoms;

        public Xcb.Connection conn {
            get {
                return this._conn;
            }
        }

        public Xcb.RandR.Connection randr {
            get {
                return this._randr;
            }
        }

        public GLib.List<weak Genesis.MonitorBackend> monitors {
            owned get {
                var list = this._monitors.get_values();
                return list;
            }
        }

        public Backend(Genesis.Shell shell) {
            Object();

            this._shell = shell;
            this._conn = new Xcb.Connection(null, out this._def_screen);
            assert(this._conn != null);

            this._randr = Xcb.RandR.get_connection(this._conn);
            assert(this._randr != null);

            this._monitors = new GLib.HashTable<string, Monitor>(GLib.str_hash, GLib.str_equal);
            this._atoms = new GLib.HashTable<string, Xcb.Atom?>(GLib.str_hash, GLib.str_equal);

            Xcb.GenericError? error = null;
            var def_screen = this.get_default_screen();
            var res_cookie = this._randr.get_screen_resources(def_screen.root);

            var res = this._randr.get_screen_resources_reply(res_cookie, out error);
            if (error == null) {
                foreach (var output in res.outputs) {
                    var monitor = new Monitor(this, output);
                    this._monitors.insert(monitor.name, monitor);
                }
            }
        }

        ~Backend() {
            this._monitors.remove_all();
        }

        private Xcb.Screen get_default_screen() {
            return this._conn.get_setup().screens[this._def_screen];
        }

        public Xcb.Atom? get_atom(string name) {
            if (this._atoms.contains(name)) {
                return this._atoms.get(name);
            }

            Xcb.GenericError? error = null;
            var atom_cookie = this._conn.intern_atom(false, name);
            var atom = this._conn.intern_atom_reply(atom_cookie, out error);
            if (error != null) return null;

            this._atoms.insert(name, atom.atom);
            return atom.atom;
        }
    }
}