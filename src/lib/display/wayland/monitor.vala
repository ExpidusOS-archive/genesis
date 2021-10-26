namespace Genesis.Wayland {
	private struct MonitorDataStore {
		public int index;
		public Gdk.Rectangle workarea;
	}

	public class Monitor : Genesis.Monitor {
		private MonitorDataStore _data_store;
		private void* _store;

		public override int index {
			get {
				return this._data_store.index;
			}
		}

		public override Gdk.Rectangle workarea {
			get {
				return this._data_store.workarea;
			}
		}

		construct {
			this._store = init_store_impl((Gdk.Wayland.Monitor)this.backend, ref this._data_store);
			assert(this._store != null);

			this.backend.set_data("genesis-wayland-monitor-store", this._store);
		}

		public Monitor(Gdk.Monitor mon) {
			Object(backend: mon);
		}

		private static extern void* init_store_impl(Gdk.Wayland.Monitor monitor, ref MonitorDataStore store);
	}
}