namespace Genesis.X11 {
	private enum WindowState {
		REMOVE = 0,
		ADD = 1,
		TOGGLE = 3
	}

	public enum Struts {
		LEFT,
		RIGHT,
		TOP,
		BOTTOM,
		LEFT_START,
		LEFT_END,
		RIGHT_START,
		RIGHT_END,
		TOP_START,
		TOP_END,
		BOTTOM_START,
		BOTTOM_END
	}

	public class DisplayWindow : Genesis.DisplayWindow {
		private bool _skip_pager_hint;
		private bool _skip_taskbar_hint;

		public override bool skip_pager_hint {
			get {
				return this._skip_pager_hint;
			}
			set {
				this._skip_pager_hint = value;
				this.update_state(this._skip_pager_hint ? WindowState.ADD : WindowState.REMOVE, "skip_pager");
			}
		}

		public override bool skip_taskbar_hint {
			get {
				return this._skip_taskbar_hint;
			}
			set {
				this._skip_taskbar_hint = value;
				this.update_state(this._skip_taskbar_hint ? WindowState.ADD : WindowState.REMOVE, "skip_taskbar");
			}
		}

		public override Gdk.Rectangle geometry {
			get {
				var gxdisp = this.backend.display as Gdk.X11.Display;
				assert(gxdisp != null);

				var gxwin = this.backend as Gdk.X11.Surface;
				assert(gxwin != null);

				var xwin = gxwin.get_xid();

				X.WindowAttributes attrs = {};
				gxdisp.get_xdisplay().get_window_attributes(xwin, out attrs);

				Gdk.Rectangle rect = {};
				rect.x = attrs.x;
				rect.y = attrs.y;
				rect.width = attrs.width;
				rect.height = attrs.height;
				return rect;
			}
			set {
				var gxdisp = this.backend.display as Gdk.X11.Display;
				assert(gxdisp != null);

				var gxwin = this.backend as Gdk.X11.Surface;
				assert(gxwin != null);

				var xwin = gxwin.get_xid();
				if (value.width > 0 && value.height > 0) {
					gxdisp.get_xdisplay().move_resize_window(xwin, value.x, value.y, value.width, value.height);
				}
			}
		}

		public override string? dbus_id {
			owned get {
				var gxdisp = this.backend.display as Gdk.X11.Display;
				assert(gxdisp != null);

				uint8[] data;
				if (this.get_property(gxdisp.get_xatom_by_name("_GTK_APPLICATION_ID"), gxdisp.get_xatom_by_name("UTF8_STRING"), 0, 128, false, out data)) {
					var sb = new GLib.StringBuilder.sized(data.length);
        	foreach (var c in data) sb.append_c((char)c);
					return sb.str;
				} else if (this.get_property(gxdisp.get_xatom_by_name("_GTK_UNIQUE_BUS_NAME"), gxdisp.get_xatom_by_name("UTF8_STRING"), 0, 128, false, out data)) {
					var sb = new GLib.StringBuilder.sized(data.length);
        	foreach (var c in data) sb.append_c((char)c);
					return sb.str;
				}
				return null;
			}
		}

		public override GLib.MenuModel? menu {
			owned get {
				var gxdisp = this.backend.display as Gdk.X11.Display;
				assert(gxdisp != null);

				uint8[] data;
				if (!this.get_property(gxdisp.get_xatom_by_name("_GTK_MENUBAR_OBJECT_PATH"), gxdisp.get_xatom_by_name("UTF8_STRING"), 0, 128, false, out data)) return null;
				var sb = new GLib.StringBuilder.sized(data.length);
        foreach (var c in data) sb.append_c((char)c);
				var gtk_menubar_obj_path = sb.str;

				var dbus_id = this.dbus_id;
				if (dbus_id == null) return null;

				try {
					var conn = GLib.Bus.get_sync(GLib.BusType.SESSION);
					return GLib.DBusMenuModel.@get(conn, dbus_id, gtk_menubar_obj_path);
				} catch (GLib.Error e) {
					GLib.error("%s (%d): %s", e.domain.to_string(), e.code, e.message);
					return null;
				}
			}
		}

		public override GLib.ActionGroup? action_group_app {
			owned get {
				var gxdisp = this.backend.display as Gdk.X11.Display;
				assert(gxdisp != null);

				uint8[] data;
				if (!this.get_property(gxdisp.get_xatom_by_name("_GTK_APPLICATION_OBJECT_PATH"), gxdisp.get_xatom_by_name("UTF8_STRING"), 0, 128, false, out data)) return null;
				var sb = new GLib.StringBuilder.sized(data.length);
        foreach (var c in data) sb.append_c((char)c);
				var gtk_application_obj_path = sb.str;

				var dbus_id = this.dbus_id;
				if (dbus_id == null) return null;

				try {
					var conn = GLib.Bus.get_sync(GLib.BusType.SESSION);
					return GLib.DBusActionGroup.@get(conn, dbus_id, gtk_application_obj_path);
				} catch (GLib.Error e) {
					GLib.error("%s (%d): %s", e.domain.to_string(), e.code, e.message);
					return null;
				}
			}
		}

		public override GLib.ActionGroup? action_group_win {
			owned get {
				var gxdisp = this.backend.display as Gdk.X11.Display;
				assert(gxdisp != null);

				uint8[] data;
				if (!this.get_property(gxdisp.get_xatom_by_name("_GTK_WINDOW_OBJECT_PATH"), gxdisp.get_xatom_by_name("UTF8_STRING"), 0, 128, false, out data)) return null;
				var sb = new GLib.StringBuilder.sized(data.length);
        foreach (var c in data) sb.append_c((char)c);
				var gtk_window_obj_path = sb.str;

				var dbus_id = this.dbus_id;
				if (dbus_id == null) return null;

				try {
					var conn = GLib.Bus.get_sync(GLib.BusType.SESSION);
					return GLib.DBusActionGroup.@get(conn, dbus_id, gtk_window_obj_path);
				} catch (GLib.Error e) {
					GLib.error("%s (%d): %s", e.domain.to_string(), e.code, e.message);
					return null;
				}
			}
		}

		public DisplayWindow(Gdk.Surface surf) {
			Object(backend: surf);
		}

		private void update_state(WindowState state, string name) {
			var gxdisp = this.backend.display as Gdk.X11.Display;
			assert(gxdisp != null);

			var gxwin = this.backend as Gdk.X11.Surface;
			assert(gxwin != null);

			var xwin = gxwin.get_xid();

			X.ClientMessageEvent client_msg = {};
			client_msg.display = gxdisp.get_xdisplay();
			client_msg.window = xwin;
			client_msg.message_type = gxdisp.get_xatom_by_name("_NET_WM_STATE");
			client_msg.format = 32;
			client_msg.l[0] = state;
			client_msg.l[1] = (long)gxdisp.get_xatom_by_name("_NET_WM_STATE_%s".printf(name.up()));
			client_msg.l[2] = 0;
			client_msg.l[3] = 0;

			X.Event ev = (X.Event)client_msg;
			gxdisp.get_xdisplay().send_event(gxdisp.get_xrootwindow(), false, X.EventType.ClientMessage, ref ev);
		}

		protected override void update_type_hint(Genesis.WindowTypeHint type) {
			string type_name = "NORMAL";

			switch (type) {
				case Genesis.WindowTypeHint.NORMAL: break;
				case Genesis.WindowTypeHint.PANEL:
					type_name = "DOCK";
					break;
				case Genesis.WindowTypeHint.DESKTOP:
					type_name = "DESKTOP";
					break;
			}

			var gxdisp = this.backend.display as Gdk.X11.Display;
			assert(gxdisp != null);

			var atom = gxdisp.get_xatom_by_name("_NET_WM_WINDOW_TYPE");
			var atom_value = gxdisp.get_xatom_by_name("_NET_WM_WINDOW_TYPE_%s".printf(type_name));

			var data = new long[1];
			data[0] = (long)atom_value;
			this.set_property(atom, X.XA_ATOM, 32, X.PropMode.Replace, (uint8[])data, 1);
		}

		public new bool set_property(X.Atom atom, X.Atom type, int fmt, int mode, uint8[] data, int n_items) {
			var gxdisp = this.backend.display as Gdk.X11.Display;
			assert(gxdisp != null);

			var gxwin = this.backend as Gdk.X11.Surface;
			assert(gxwin != null);

			unowned var xdisp = gxdisp.get_xdisplay();
			var xwin = gxwin.get_xid();

			return xdisp.change_property(xwin, atom, type, fmt, mode, (uchar[])data, n_items) == X.Success;
		}

		public new bool get_property(X.Atom atom, X.Atom type, long offset, long length, bool @delete, out uint8[] data) {
			var gxdisp = this.backend.display as Gdk.X11.Display;
			assert(gxdisp != null);

			var gxwin = this.backend as Gdk.X11.Surface;
			assert(gxwin != null);

			unowned var xdisp = gxdisp.get_xdisplay();
			var xwin = gxwin.get_xid();

			X.Atom real_type;
			int real_fmt;
			ulong n_items;
			ulong bar;
			void* prop_ret = null;
			data = new uint8[0];
			var success = xdisp.get_window_property(xwin, atom, offset, length, @delete, type, out real_type, out real_fmt, out n_items, out bar, out prop_ret) == X.Success;

			if (!success) return false;
			if (real_type != type) return false;

			data = new uint8[n_items];
			GLib.Memory.copy(data, prop_ret, n_items * sizeof (ulong));
			return true;
		}
	}
}