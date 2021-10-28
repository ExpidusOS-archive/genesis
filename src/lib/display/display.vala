namespace Genesis {
	public abstract class Display : GLib.Object {
		private Gdk.Display _backend;
		private GLib.ListModel _monitors;
		private static GLib.HashTable<Gdk.Display, Display> display_store;

		public abstract Genesis.DisplayWindow? active_window { owned get; }

		public Gdk.Display backend {
			get {
				return this._backend;
			}
			construct {
				this._backend = value;
			}
		}

		construct {
			this._monitors = new MonitorList(this.backend.get_monitors());
		}

		public Monitor? find_monitor(string name) {
			for (var i = 0; i < this._monitors.get_n_items(); i++) {
				var mon = this._monitors.get_item(i) as Genesis.Monitor;
				if (mon == null) continue;

				if (mon.backend.get_model() == name) return mon;
			}

			int index = 0;
			if (int.try_parse(name, out index)) {
				return (Genesis.Monitor)this._monitors.get_item(index);
			}
			return null;
		}

		public unowned GLib.ListModel get_monitors() {
			return this._monitors;
		}

		public signal void active_window_changed();

		public static Display? from(Gdk.Display disp) {
			if (display_store == null) display_store = new GLib.HashTable<Gdk.Display, Display>(GLib.direct_hash, GLib.direct_equal);
			else if (display_store.contains(disp)) return display_store.get(disp);

#if BUILD_X11
			if (disp is Gdk.X11.Display) {
				var inst = new Genesis.X11.Display(disp);
				display_store.set(disp, inst);
				return inst;
			} else
#endif
#if BUILD_WAYLAND
			if (disp is Gdk.Wayland.Display) {
				var inst = new Genesis.Wayland.Display(disp);
				display_store.set(disp, inst);
				return inst;
			}
#endif
			{}
			return null;
		}
	}

	protected class MonitorList : GLib.Object, GLib.ListModel {
		private ulong _changed_id;
		private GLib.ListModel _monitors;

		public GLib.ListModel monitors {
			get {
				return this._monitors;
			}
			construct {
				this._monitors = value;
			}
		}

		construct {
			this._changed_id = this._monitors.items_changed.connect((pos, rem, add) => {
				this.items_changed(pos, rem, add);
			});
		}

		public MonitorList(GLib.ListModel monitors) {
			Object(monitors: monitors);
		}

		~MonitorList() {
			if (this._changed_id > 0) this._monitors.disconnect(this._changed_id);
		}

		public GLib.Object? get_item(uint pos) {
			var item = this._monitors.get_item(pos) as Gdk.Monitor;
			if (item == null) return null;
			return Genesis.Monitor.from(item);
		}

		public GLib.Type get_item_type() {
			return typeof (Genesis.Monitor);
		}

		public uint get_n_items() {
			return this._monitors.get_n_items();
		}
	}
}