namespace Genesis {
	public enum PanelSide {
		TOP,
		LEFT,
		RIGHT,
		BOTTOM
	}

	public class Panel : Window {
		private PanelSide _side;
		private int _width;
		private int _height = 15;
		private int _padding_top;
		private int _padding_left;
		private int _padding_right;
		private int _padding_bottom;

		public int width {
			get {
				return this._width;
			}
			set construct {
				this._width = value;
				this.queue_resize();
				this.update_side();
			}
		}

		public int height {
			get {
				return this._height;
			}
			set construct {
				this._height = value;
				this.queue_resize();
				this.update_side();
			}
		}

		public PanelSide side {
			get {
				return this._side;
			}
			set construct {
				this._side = value;
				this.update_side();
			}
		}

		public int padding_top {
			get {
				return this._padding_top;
			}
			set construct {
				this._padding_top = value;
				this.update_side();
			}
		}

		public int padding_left {
			get {
				return this._padding_left;
			}
			set construct {
				this._padding_left = value;
				this.update_side();
			}
		}

		public int padding_right {
			get {
				return this._padding_right;
			}
			set construct {
				this._padding_right = value;
				this.update_side();
			}
		}

		public int padding_bottom {
			get {
				return this._padding_bottom;
			}
			set construct {
				this._padding_bottom = value;
				this.update_side();
			}
		}

		construct {
			this.type_hint = Genesis.WindowTypeHint.PANEL;
      this.decorated = false;
			this.skip_pager_hint = true;
			this.skip_taskbar_hint = true;
      this.resizable = false;

			this.get_style_context().remove_class("solid-csd");

			this.update_side();
		}

		public int get_computed_width() {
			return (this.width == 0 ? this.monitor.geometry.width : (int)this.compute_size(this.width)) - this.padding_right;
		}

		public int get_computed_height() {
			var v = this.height == 0 ? (int)this.compute_size(15) : (int)this.compute_size(this.height);
			return v;
		}

		public override void map() {
			base.map();
			this.update_side();

#if BUILD_X11
			var xsurf = this.get_window().backend as Gdk.X11.Surface;
			if (xsurf != null) xsurf.set_utf8_property("_NET_WM_NAME", "genesis-panel");
#endif
		}

		public override void measure(Gtk.Orientation ori, int for_size, out int min, out int nat, out int min_base, out int nat_base) {
			min_base = -1;
			nat_base = -1;
			min = 0;
			nat = 0;

			if (this.monitor != null) {
				switch (ori) {
					case Gtk.Orientation.HORIZONTAL:
						min = nat = this.get_computed_width();
						break;
					case Gtk.Orientation.VERTICAL:
						min = nat = this.get_computed_height();
						break;
				}
			} else {
				base.measure(ori, for_size, out min, out nat, out min_base, out nat_base);
			}
		}

		private void update_side() {
			if (this.get_display() == null) return;

#if BUILD_X11
			if (this.get_display() is Genesis.X11.Display) {
				if (this.get_mapped()) {
					var win = this.get_window() as Genesis.X11.DisplayWindow;
					return_if_fail(win != null);

					long struts[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
					unowned var xscreen = ((Gdk.X11.Display)this.get_display().backend).get_xscreen();

					switch (this.side) {
						case PanelSide.TOP:
						default:
							this.move(this.monitor.geometry.x + this.padding_left, this.monitor.geometry.y + this.padding_top);

							struts[Genesis.X11.Struts.TOP] = (this.get_computed_height() + this.monitor.geometry.y) * this.scale_factor;
							struts[Genesis.X11.Struts.TOP_START] = (this.monitor.geometry.x * this.scale_factor);
							struts[Genesis.X11.Struts.TOP_END] = (this.monitor.geometry.x + this.monitor.geometry.width) * this.scale_factor - 1;
							break;
						case PanelSide.LEFT:
							this.move(this.monitor.geometry.x + this.padding_left, this.monitor.geometry.y + this.padding_top);
							struts[Genesis.X11.Struts.LEFT] = (this.monitor.geometry.x + this.get_computed_height()) * this.scale_factor;
							struts[Genesis.X11.Struts.LEFT_START] = this.monitor.geometry.y * this.scale_factor;
							struts[Genesis.X11.Struts.LEFT_END] = (this.monitor.geometry.y + this.monitor.geometry.height) * this.scale_factor - 1;
							break;
						case PanelSide.RIGHT:
							this.move((this.monitor.geometry.x + this.monitor.geometry.width) - (this.padding_left + this.get_computed_width()), this.monitor.geometry.y + this.padding_top);
							struts[Genesis.X11.Struts.RIGHT] = (xscreen.width + this.get_computed_width()) - (this.monitor.geometry.x + this.monitor.geometry.width) * this.scale_factor;
							struts[Genesis.X11.Struts.RIGHT_START] = this.monitor.geometry.y * this.scale_factor;
							struts[Genesis.X11.Struts.RIGHT_END] = (this.monitor.geometry.y + this.monitor.geometry.height) * this.scale_factor - 1;
							break;
						case PanelSide.BOTTOM:
							this.move(this.monitor.geometry.x + this.padding_left + ((int)(this.monitor.geometry.width / 2) - (int)(this.get_computed_width() / 2)), ((this.monitor.geometry.y + this.monitor.geometry.height) - (this.padding_bottom + this.get_computed_height())));
							struts[Genesis.X11.Struts.BOTTOM] = (this.get_computed_height() + xscreen.height - this.monitor.geometry.y - this.monitor.geometry.height) * this.scale_factor;
							struts[Genesis.X11.Struts.BOTTOM_START] = this.monitor.geometry.x * this.scale_factor;
							struts[Genesis.X11.Struts.BOTTOM_END] = (this.monitor.geometry.x + this.monitor.geometry.width) * this.scale_factor - 1;
							break;
					}

					this.set_default_size(this.get_computed_width(), this.get_computed_height());

					win.set_property("_NET_WM_STRUT", "CARDINAL", 32, X.PropMode.Replace, (uint8[])struts, 4);
					win.set_property("_NET_WM_STRUT_PARTIAL", "CARDINAL", 32, X.PropMode.Replace, (uint8[])struts, 12);
				}
			} else
#endif
#if BUILD_WAYLAND
			if (this.get_display() is Genesis.Wayland.Display) {
			} else
#endif
			{
				GLib.error("Failed to get a compatible display backend for panel");
			}
		}
	}
}