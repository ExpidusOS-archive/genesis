namespace Genesis.X11 {
	public class Display : Genesis.Display {
		private ulong _xev_id;

		public override Genesis.DisplayWindow? active_window {
			owned get {
				var gxdisplay = this.backend as Gdk.X11.Display;
				assert(gxdisplay != null);

				unowned var xdisp = gxdisplay.get_xdisplay();
				var atom = xdisp.intern_atom("_NET_ACTIVE_WINDOW", false);

				X.Atom real_type;
				int real_fmt;
				ulong n_items;
				ulong bar;
				void* prop_ret = null;
				xdisp.get_window_property(gxdisplay.get_xrootwindow(), atom, 0, 32, false, X.XA_WINDOW, out real_type, out real_fmt, out n_items, out bar, out prop_ret);

				var data = new ulong[n_items];
				GLib.Memory.copy(data, prop_ret, n_items * sizeof (ulong));

				if (data != null && n_items > 0) {
					return Genesis.DisplayWindow.from(Gdk.X11.Surface.lookup_for_display(gxdisplay, (X.Window)data[0]));
				}
				return null;
			}
		}

		construct {
			var gxdisp = (Gdk.X11.Display)this.backend;
			gxdisp.get_xdisplay().select_input(gxdisp.get_xrootwindow(), X.EventMask.PropertyChangeMask);

			this._xev_id = gxdisp.xevent.connect((xev) => {
				if (xev.type == X.EventType.PropertyNotify) {
					if (xev.xproperty.window == gxdisp.get_xrootwindow()) {
						unowned var xdisp = gxdisp.get_xdisplay();
						if (xev.xproperty.atom == xdisp.intern_atom("_NET_ACTIVE_WINDOW", false)) {
							var type = this.get_type();
							var cref = type.class_ref();
							unowned var obj_class = (GLib.ObjectClass)cref;

							foreach (var pspec in obj_class.list_properties()) {
								if (pspec.get_name() == "active-window") {
									this.notify["active-window"](pspec);
									break;
								}
							}
							return true;
						}
					}
				}
				return false;
			});
		}

		public Display(Gdk.Display disp) {
			Object(backend: disp);
		}

		~Display() {
			this.backend.disconnect(this._xev_id);
		}
	}
}