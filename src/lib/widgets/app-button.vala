namespace Genesis {
	public class AppButton : Gtk.Widget, Widget {
		private GLib.AppInfo? _app_info = null;
		private string _app_id = "";
		private int _icon_size;
		private string _icon_name = "application-x-executable";
		private GLib.Icon? _gicon = null;
		private string _app_label = "Untitled Application";
		private Gtk.GestureClick _gesture;

		private Gtk.Image _icon;
		private Gtk.Label _label;

		public GLib.AppInfo? app_info {
			get {
				return this._app_info;
			}
			set construct {
				this._app_info = value;
				if (this._app_info != null) {
					this.application_id = value.get_id();
					this.label = value.get_display_name();
					this.gicon = value.get_icon();
				}
			}
		}

		public string application_id {
			get {
				return this._app_id;
			}
			set construct {
				this._app_id = value;
			}
		}

		public int icon_size {
			get {
				return this._icon_size;
			}
			set construct {
				this._icon_size = value;
				this.update_icon_size();
			}
		}

		public new string icon_name {
			get {
				return this._icon_name;
			}
			set construct {
				this._icon_name = value;
				if (this._icon != null) this._icon.icon_name = value;
			}
		}

		public new GLib.Icon? gicon {
			get {
				return this._gicon;
			}
			set construct {
				this._gicon = value;
				if (this._icon != null) this._icon.gicon = value;
			}
		}

		public new string label {
			get {
				return this._app_label;
			}
			set construct {
				this._app_label = value;
				if (this._label != null) this._label.label = value;
			}
		}

		public AppButton() {
			Object();
		}

		public AppButton.from_id(string app_id) {
			var app_info = new GLib.DesktopAppInfo(app_id);
			Object(app_info: app_info);
		}

		class construct {
			set_layout_manager_type(typeof (Gtk.BoxLayout));
		}

		construct {
			if (this._icon_size == 0) this._icon_size = 25;

			this._icon = new Gtk.Image.from_icon_name(this._icon_name);
			this._label = new Gtk.Label(this._app_label);

			this._icon.set_parent(this);
			this._label.set_parent(this);

			if (this.gicon != null) this._icon.gicon = this.gicon;

			this._gesture = new Gtk.GestureClick();
			this._gesture.released.connect((n_press, x, y) => {
				if (n_press == 1) {
					try {
						if (this.app_info != null) this.app_info.launch(null, null);
					} catch (GLib.Error e) {}
				}
			});
			this.add_controller(this._gesture);

			var layout = (Gtk.BoxLayout)this.get_layout_manager();
			layout.orientation = Gtk.Orientation.VERTICAL;

			this.update_icon_size();
		}

		public override void map() {
			base.map();

			this.update_icon_size();
		}

		public override void size_allocate(int width, int height, int baseline) {}

		public override void measure(Gtk.Orientation ori, int for_size, out int min, out int nat, out int min_base, out int nat_base) {
			int min_icon;
			int nat_icon;
			int min_base_icon;
			int nat_base_icon;
			this._icon.measure(ori, for_size, out min_icon, out nat_icon, out min_base_icon, out nat_base_icon);

			int min_label;
			int nat_label;
			int min_base_label;
			int nat_base_label;
			this._label.measure(ori, for_size, out min_label, out nat_label, out min_base_label, out nat_base_label);

			min = min_icon + min_label + 25;
			nat = nat_icon + nat_label + 25;
			min_base = min_base_icon + min_base_label;
			nat_base = nat_base_icon + nat_base_label;
		}

		private void update_icon_size() {
			if (this.get_mapped()) {
				this._icon.pixel_size = (int)this.compute_size(this._icon_size);
			}
		}
	}
}