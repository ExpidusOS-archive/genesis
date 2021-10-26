namespace Genesis.Wayland {
	public class Display : Genesis.Display {
		private void* _store;

		public override DisplayWindow? active_window {
			owned get {
				return null;
			}
		}

		construct {
			this._store = init_store_impl((Gdk.Wayland.Display)this.backend);
			assert(this._store != null);

			this.backend.set_data("genesis-wayland-display-store", this._store);
		}

		public Display(Gdk.Display disp) {
			Object(backend: disp);
		}

		private static extern void* init_store_impl(Gdk.Wayland.Display display);
	}
}