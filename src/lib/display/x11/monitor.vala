namespace Genesis.X11 {
	public class Monitor : Genesis.Monitor {
		private ulong _xev_id;

		public override int index {
			get {
				var mons = this.backend.display.get_monitors();
				for (var i = 0; i < mons.get_n_items(); i++) {
					var mon = (Gdk.Monitor)mons.get_item(i);
					if (mon.geometry.equal(this.backend.geometry)) return i;
				}
				return -1;
			}
		}

		public override Gdk.Rectangle workarea {
			get {
				var gxdisplay = this.backend.display as Gdk.X11.Display;
				assert(gxdisplay != null);

				unowned var xdisp = gxdisplay.get_xdisplay();
				var atom = xdisp.intern_atom("_NET_WORKAREA", false);

				X.Atom real_type;
				int real_fmt;
				ulong n_items;
				ulong bar;
				void* prop_ret = null;
				xdisp.get_window_property(gxdisplay.get_xrootwindow(), atom, 0, 32, false, X.XA_CARDINAL, out real_type, out real_fmt, out n_items, out bar, out prop_ret);

				var data = new ulong[n_items];
				GLib.Memory.copy(data, prop_ret, n_items * sizeof (ulong));

				Gdk.Rectangle rect = {};
				if (data != null && n_items > 0) {
					rect.x = (int)data[this.index * 4];
					rect.y = (int)data[(this.index * 4) + 1];
					rect.width = (int)data[(this.index * 4) + 2];
					rect.height = (int)data[(this.index * 4) + 3];
				}
				return rect;
			}
		}

		construct {
			var gxdisp = (Gdk.X11.Display)this.backend.display;
			gxdisp.get_xdisplay().select_input(gxdisp.get_xrootwindow(), X.EventMask.PropertyChangeMask);

			this._xev_id = gxdisp.xevent.connect((xev) => {
				if (xev.type == X.EventType.PropertyNotify) {
					if (xev.xproperty.window == gxdisp.get_xrootwindow()) {
						unowned var xdisp = gxdisp.get_xdisplay();
						if (xev.xproperty.atom == xdisp.intern_atom("_NET_WORKAREA", false)) {
							var type = this.get_type();
							var cref = type.class_ref();
							unowned var obj_class = (GLib.ObjectClass)cref;

							this.notify_property("workarea");
							this.workarea_updated();
							return true;
						}
					}
				}
				return false;
			});
		}

		public Monitor(Gdk.Monitor mon) {
			Object(backend: mon);
		}

		~Monitor() {
			this.backend.display.disconnect(this._xev_id);
		}
	}
}