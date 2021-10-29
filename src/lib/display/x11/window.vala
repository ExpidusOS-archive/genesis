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
		private X.Window _xid;
		private unowned X.Display _xdisp;

		public X.Window xid {
			get {
				return this.backend == null ? this._xid : ((Gdk.X11.Surface)this.backend).get_xid();
			}
		}

		public X.Display xdisp {
			get {
				return this.backend == null ? this._xdisp : ((Gdk.X11.Display)(this.backend.display)).get_xdisplay();
			}
			construct {
				this._xdisp = value;
			}
		}

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
				X.WindowAttributes attrs = {};
				this.xdisp.get_window_attributes(this.xid, out attrs);

				Gdk.Rectangle rect = {};
				rect.x = attrs.x;
				rect.y = attrs.y;
				rect.width = attrs.width;
				rect.height = attrs.height;
				return rect;
			}
			set {
				if (value.width > 0 && value.height > 0) {
					this.xdisp.move_resize_window(this.xid, value.x, value.y, value.width, value.height);
				}
			}
		}

		public override string? dbus_id {
			owned get {
				string? data;
				if (this.get_utf8_property("_GTK_APPLICATION_ID", 0, false, out data)) {
					return data;
				} else if (this.get_utf8_property("_GTK_UNIQUE_BUS_NAME", 0, false, out data)) {
					return data;
				}
				return null;
			}
		}

		public override GLib.MenuModel? menu {
			owned get {
				string? gtk_menubar_obj_path;
				if (!this.get_utf8_property("_GTK_MENUBAR_OBJECT_PATH", 0, false, out gtk_menubar_obj_path)) return null;

				var dbus_id = this.dbus_id;
				if (dbus_id == null) return null;

				try {
					var conn = GLib.Bus.get_sync(GLib.BusType.SESSION);
					return GLib.DBusMenuModel.@get(conn, dbus_id, gtk_menubar_obj_path);
				} catch (GLib.Error e) {
					GLib.error("%s (%d): %s", e.domain.to_string(), e.code, e.message);
				}
			}
		}

		public override GLib.ActionGroup? action_group_app {
			owned get {
				string? gtk_application_obj_path;
				if (!this.get_utf8_property("_GTK_APPLICATION_OBJECT_PATH", 0, false, out gtk_application_obj_path)) return null;

				var dbus_id = this.dbus_id;
				if (dbus_id == null) return null;

				try {
					var conn = GLib.Bus.get_sync(GLib.BusType.SESSION);
					return GLib.DBusActionGroup.@get(conn, dbus_id, gtk_application_obj_path);
				} catch (GLib.Error e) {
					GLib.error("%s (%d): %s", e.domain.to_string(), e.code, e.message);
				}
			}
		}

		public override GLib.ActionGroup? action_group_win {
			owned get {
				string? gtk_window_obj_path;
				if (!this.get_utf8_property("_GTK_WINDOW_OBJECT_PATH", 0, false, out gtk_window_obj_path)) return null;

				var dbus_id = this.dbus_id;
				if (dbus_id == null) return null;

				try {
					var conn = GLib.Bus.get_sync(GLib.BusType.SESSION);
					return GLib.DBusActionGroup.@get(conn, dbus_id, gtk_window_obj_path);
				} catch (GLib.Error e) {
					GLib.error("%s (%d): %s", e.domain.to_string(), e.code, e.message);
				}
			}
		}

		public DisplayWindow(Gdk.Surface surf) {
			Object(backend: surf);
		}

		public DisplayWindow.from_xid(X.Display xdisp, X.Window xid) {
			Object(backend: null, xdisp: xdisp);
			this._xid = xid;
		}

		private void update_state(WindowState state, string name) {
			X.ClientMessageEvent client_msg = {};
			client_msg.display = this.xdisp;
			client_msg.window = this.xid;
			client_msg.message_type = this.xdisp.intern_atom("_NET_WM_STATE", false);
			client_msg.format = 32;
			client_msg.l[0] = state;
			client_msg.l[1] = (long)this.xdisp.intern_atom("_NET_WM_STATE_%s".printf(name.up()), false);
			client_msg.l[2] = 0;
			client_msg.l[3] = 0;

			X.Event ev = (X.Event)client_msg;
			this.xdisp.send_event(this.xdisp.default_root_window(), false, X.EventType.ClientMessage, ref ev);
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

			var atom_value = this.xdisp.intern_atom("_NET_WM_WINDOW_TYPE_%s".printf(type_name), false);

			var data = new long[1];
			data[0] = (long)atom_value;
			this.set_property("_NET_WM_WINDOW_TYPE", "ATOM", 32, X.PropMode.Replace, (uint8[])data, 1);
		}

		public new bool set_property(string atom, string type, int fmt, int mode, uint8[] data, int n_items) {
			return this.xdisp.change_property(this.xid, this.xdisp.intern_atom(atom, false), this.xdisp.intern_atom(type, false), fmt, mode, (uchar[])data, n_items) == X.Success;
		}

		public new bool get_property(string atom, string type, long offset, long length, bool @delete, out uint8[] data) {
			X.Atom real_type;
			int real_fmt;
			ulong n_items;
			ulong bar;
			void* prop_ret = null;
			data = new uint8[0];
			var type_atom = this.xdisp.intern_atom(type, false);
			var success = this.xdisp.get_window_property(this.xid, this.xdisp.intern_atom(atom, false), offset, length, @delete, type_atom, out real_type, out real_fmt, out n_items, out bar, out prop_ret) == X.Success;

			if (!success) return false;
			if (real_type != type_atom) return false;

			data = new uint8[n_items];
			GLib.Memory.copy(data, prop_ret, n_items * sizeof (ulong));
			return true;
		}

		public bool get_utf8_property(string atom, long offset, bool @delete, out string? data) {
			data = null;

			X.Atom real_type;
			int real_fmt;
			ulong n_items;
			ulong bar;
			void* prop_ret = null;
			var raw_data = new uint8[0];
			var type_atom = this.xdisp.intern_atom("UTF8_STRING", false);
			var atom_name = this.xdisp.intern_atom(atom, false);
			var success = this.xdisp.get_window_property(this.xid, atom_name, offset, 1, false, type_atom, out real_type, out real_fmt, out n_items, out bar, out prop_ret) == X.Success;

			if (!success) return false;
			if (real_type != type_atom) return false;

			success = this.xdisp.get_window_property(this.xid, atom_name, offset, (long)bar, @delete, type_atom, out real_type, out real_fmt, out n_items, out bar, out prop_ret) == X.Success;

			if (!success) return false;
			if (real_type != type_atom) return false;

			raw_data = new uint8[n_items];
			stdout.printf("%lu\n", n_items);
			GLib.Memory.copy(raw_data, prop_ret, n_items * sizeof (ulong));

			var sb = new GLib.StringBuilder.sized(raw_data.length);
      foreach (var c in raw_data) sb.append_c((char)c);
			data = sb.str;
			return true;
		}

		public bool has_child_xid(X.Window xid) {
			X.Window root_ret;
			X.Window parent_ret;
			X.Window[] children;
			this.xdisp.query_tree(this.xid, out root_ret, out parent_ret, out children);
			foreach (var child in children) {
				if (child == xid) return true;
			}

			foreach (var child in children) {
				var c = new DisplayWindow.from_xid(this.xdisp, child);
				if (c.has_child_xid(xid)) return true;
			}
			return false;
		}
	}
}