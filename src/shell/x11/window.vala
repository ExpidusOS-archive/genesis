namespace Genesis.X11 {
    public class Window : Genesis.WindowBackend {
        private Backend _backend;
        private Xcb.Window _wid;

        public override bool is_managed {
            get {
                Xcb.GenericError? error = null;
                var cookie = this._backend.conn.get_window_attributes(this.wid);
                var attrs = this._backend.conn.get_window_attributes_reply(cookie, out error);
                if (error == null) {
                    return attrs.override_redirect != 0;
                }
                return true;
            }
        }

        public Xcb.Window wid {
            get {
                return this._wid;
            }
        }

        public Window(Backend backend, Xcb.Window wid) {
            Object();

            this._backend = backend;
            this._wid = wid;
        }

        ~Window() {
            this._backend.conn.destroy_window(this.wid);
            stdout.printf("Destroyed window %lu\n", this.wid);
        }

        public override void map() {
            this._backend.conn.map_window(this.wid);
            this._backend.conn.flush();

            uint32[] check = {
              Xcb.EventMask.ENTER_WINDOW |
              Xcb.EventMask.FOCUS_CHANGE
            };

            var cookie = this._backend.conn.change_window_attributes_checked(this.wid, Xcb.CW.EVENT_MASK, check);
            var error = this._backend.conn.request_check(cookie);
            if (error != null) {
                stderr.printf("Failed to map window %lu\n", this.wid);
            }
        }

        public override void raise() {
            {
                uint32[] values = { 0 };
                var cookie = this._backend.conn.configure_window_checked(this.wid, Xcb.ConfigWindow.STACK_MODE, values);
                var error = this._backend.conn.request_check(cookie);
                if (error != null) {
                    stderr.printf("Failed to raise window %lu\n", this.wid);
                }
            }

            var _NET_ACTIVE_WINDOW = this._backend.get_atom("_NET_ACTIVE_WINDOW");
            var WINDOW = this._backend.get_atom("WINDOW");

            {
                uint32[] values = { this.wid };
                this._backend.conn.change_property_uint32(Xcb.PropMode.REPLACE, this._backend.get_default_screen().root, _NET_ACTIVE_WINDOW, WINDOW, 1, values);
            }
        }

        public override void focus() {
            this._backend.conn.set_input_focus(Xcb.InputFocus.POINTER_ROOT, this.wid, 0);
        }

        public override void configure(uint32 x, uint32 y, uint32 width, uint32 height) {
            var mask = Xcb.ConfigWindow.X | Xcb.ConfigWindow.Y | Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT;

            uint32[] values = {
                x, y,
                width, height
            };

            this._backend.conn.configure_window(this.wid, mask, values);
        }

        public override string to_string() {
            return "%lu".printf(this.wid);
        }
    }
}