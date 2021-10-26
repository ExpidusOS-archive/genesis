namespace Genesis {
	public abstract class Monitor : GLib.Object {
		private Gdk.Monitor _backend;

		public Gdk.Monitor backend {
			get {
				return this._backend;
			}
			construct {
				this._backend = value;
			}
		}

		public abstract int index { get; }
		public abstract Gdk.Rectangle workarea { get; }

		public double dpi {
			get {
				var diag_inch = GLib.Math.sqrt(GLib.Math.pow(this.backend.width_mm, 2) + GLib.Math.pow(this.backend.height_mm, 2)) * 0.039370;
				var diag_px = GLib.Math.sqrt(GLib.Math.pow(this.geometry.width, 2) + GLib.Math.pow(this.geometry.height, 2));
				return diag_px / diag_inch;
			}
		}

		public Gdk.Rectangle geometry {
			get {
				return this.backend.geometry;
			}
		}

		public static Monitor? from(Gdk.Monitor mon) {
#if BUILD_X11
			if (mon is Gdk.X11.Monitor) {
				return new Genesis.X11.Monitor(mon);
			} else
#endif
			{}
			return null;
		}
	}
}