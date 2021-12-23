namespace GenesisShell {
	public abstract class WindowLayout : GenesisCommon.BasicLayout {
		private Window _window;

		public Window window {
			get {
				return this._window;
			}
			construct {
				this._window = value;
			}
		}

		public virtual GenesisCommon.LayoutWindowingMode windowing_mode {
			get {
				return GenesisCommon.LayoutWindowingMode.FLOATING;
			}
		}

		public virtual Gdk.Rectangle geometry {
			get {
				return { 0, 0, 0, 0 };
			}
		}

		public override GenesisCommon.Monitor? monitor {
			owned get {
				return this.window.shell.find_monitor(this.window.monitor_name);
			}
		}

		public override Cairo.Surface? draw_region(Gdk.Rectangle rect) {
			var img_surf = new Cairo.ImageSurface(Cairo.Format.ARGB32, this.geometry.width, this.geometry.height);
			Cairo.Context cr = new Cairo.Context(img_surf);
			this.draw(cr);
			return new Cairo.Surface.for_rectangle(img_surf, rect.x, rect.y, rect.width, rect.height);
		}
	}

	public abstract class Layout : GenesisCommon.Layout {
		public virtual WindowLayout? get_window_layout(Window win) {
			return null;
		}
	}
}