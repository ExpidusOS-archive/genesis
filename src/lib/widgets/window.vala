namespace Genesis {
	public class Window : Adw.ApplicationWindow, Widget {
		private string? _monitor_name = null;
		private ulong _monitor_update_id = 0;
		private bool _init_skip_pager_hint;
		private bool _init_skip_taskbar_hint;
		private Gdk.Rectangle _init_geometry = {};
		private WindowTypeHint _init_type_hint;
		private bool _monitor_size;

		public string? monitor_name {
			get {
				return this._monitor_name;
			}
			set construct {
				if (this.get_mapped()) this.update_monitor(value);
				else this._monitor_name = value;
				this.queue_resize();
			}
		}

		public bool skip_pager_hint {
			get {
				if (this.get_mapped()) {
					return this.get_window().skip_pager_hint;
				}
				return this._init_skip_pager_hint;
			}
			set {
				this._init_skip_pager_hint = value;
				if (this.get_mapped()) {
					this.get_window().skip_pager_hint = value;
				}
			}
		}

		public bool skip_taskbar_hint {
			get {
				if (this.get_mapped()) {
					return this.get_window().skip_taskbar_hint;
				}
				return this._init_skip_taskbar_hint;
			}
			set {
				this._init_skip_taskbar_hint = value;
				if (this.get_mapped()) {
					this.get_window().skip_taskbar_hint = value;
				}
			}
		}

		public WindowTypeHint type_hint {
			get {
				if (this.get_mapped()) {
					var val = this.get_window().type_hint;
					if (val != this._init_type_hint) {
						this.get_window().type_hint = this._init_type_hint;
						return this._init_type_hint;
					}
					return val;
				}
				return this._init_type_hint;
			}
			set {
				this._init_type_hint = value;
				if (this.get_mapped()) {
					this.get_window().type_hint = value;
				}
			}
		}

		public Gdk.Rectangle geometry {
			get {
				if (this.get_mapped()) {
					var val = this.get_window().geometry;
					if (!val.equal(this._init_geometry)) {
						this.get_window().geometry = this._init_geometry;
						return this._init_geometry;
					}
					return val;
				}
				return this._init_geometry;
			}
			set {
				this._init_geometry = value;
				if (this.get_mapped()) {
					this.get_window().geometry = this._init_geometry;
				}
			}
		}

		public Monitor? monitor {
			owned get {
				if (this.monitor_name != null) {
					var disp = this.get_display();
					if (disp == null) return null;
					return disp.find_monitor(this._monitor_name);
				}
				return null;
			}
		}

		public bool monitor_size {
			get {
				return this._monitor_size;
			}
			set construct {
				this._monitor_size = value;
			}
		}

		construct {
			this.set_default_size(10, 10);
		}

		public new void set_default_size(int width, int height) {
			base.set_default_size(width, height);
			this.resize(width, height);
		}

		public void resize(int width, int height) {
			var geo = this.geometry;
			geo.width = width;
			geo.height = height;
			this.geometry = geo;
		}

		public void move(int x, int y) {
			var geo = this.geometry;
			geo.x = x;
			geo.y = y;
			this.geometry = geo;
		}

		public void measure_for_monitor(Gtk.Orientation ori, int for_size, out int min, out int nat, out int min_base, out int nat_base) {
			min_base = -1;
			nat_base = -1;
			min = 0;
			nat = 0;

			switch (ori) {
				case Gtk.Orientation.HORIZONTAL:
					min = nat = this.monitor.geometry.width;
					break;
				case Gtk.Orientation.VERTICAL:
					min = nat = this.monitor.geometry.height;
					break;
			}
		}

		public override void measure(Gtk.Orientation ori, int for_size, out int min, out int nat, out int min_base, out int nat_base) {
			min_base = -1;
			nat_base = -1;
			min = 0;
			nat = 0;

			if (this.monitor == null) {
				base.measure(ori, for_size, out min, out nat, out min_base, out nat_base);
			} else {
				if (this.monitor_size) {
					this.measure_for_monitor(ori, for_size, out min, out nat, out min_base, out nat_base);
				} else {
					base.measure(ori, for_size, out min, out nat, out min_base, out nat_base);
				}
			}

			min_base = -1;
			nat_base = -1;
		}

		public override void map() {
			base.map();

			var win = this.get_window();
			win.skip_pager_hint = this._init_skip_pager_hint;
			win.skip_taskbar_hint = this._init_skip_taskbar_hint;
			win.type_hint = this._init_type_hint;
			win.geometry = this._init_geometry;

			if (this.monitor_name != null && this.monitor != null && this.monitor_size) {
				this.set_default_size(this.monitor.geometry.width, this.monitor.geometry.height);
				win.geometry = this.monitor.geometry;
			}

#if BUILD_X11
			if (this.application != null) {
				var xsurf = this.get_window().backend as Gdk.X11.Surface;
				if (xsurf != null) {
					xsurf.set_utf8_property("_GTK_APPLICATION_ID", this.application.application_id);
					xsurf.set_utf8_property("_GTK_APPLICATION_OBJECT_PATH", "/%s".printf(this.application.application_id.replace(".", "/")));
					xsurf.set_utf8_property("_GTK_WINDOW_OBJECT_PATH", "/%s/window/%lu".printf(this.application.application_id.replace(".", "/"), ((Gtk.ApplicationWindow)this).get_id()));
					if (this.application.get_menubar() != null) {
						xsurf.set_utf8_property("_GTK_MENUBAR_OBJECT_PATH", "/%s/menus/menubar".printf(this.application.application_id.replace(".", "/")));
					}
				}
			}
#endif

			this.update_monitor(this.monitor_name);
		}

		public new void queue_resize() {
			base.queue_resize();

			if (this.get_mapped()) {
				var win = this.get_window();
				if (this.monitor_name != null && this.monitor != null && this.monitor_size) {
					this.set_default_size(this.monitor.geometry.width, this.monitor.geometry.height);
					win.geometry = this.monitor.geometry;
				}
			}
		}

		private void update_monitor(string? monitor_name) {
			if (this.monitor_size) {
				if (this.monitor != null && this._monitor_update_id > 0) {
					this.monitor.backend.disconnect(this._monitor_update_id);
					this._monitor_update_id = 0;
				}
			
				this._monitor_name = monitor_name;

				if (this.monitor != null && this._monitor_update_id == 0) {
					this._monitor_update_id = this.monitor.backend.notify["geometry"].connect(() => {
						this.get_window().geometry = this.monitor.geometry;
					});
				}
			}
		}
	}
}