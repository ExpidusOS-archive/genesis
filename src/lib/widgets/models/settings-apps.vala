namespace Genesis {
	public class SettingsAppModel : GLib.Object, GLib.ListModel {
		private string? _schema_id;
		private string? _schema_key;
		private GLib.Settings _settings;
		private ulong _notify_id;
		private int _length;

		public string? schema_id {
			get {
				return this._schema_id;
			}
			set construct {
				this._schema_id = value;

				this.clear_notify_id();
				this._settings = null;
				this.check_init();
			}
		}

		public string? schema_key {
			get {
				return this._schema_key;
			}
			set construct {
				this._schema_key = value;

				this.clear_notify_id();
				this._settings = null;
				this.check_init();
			}
		}

		construct {
			this.check_init();
		}

		public SettingsAppModel() {
			Object();
		}

		public SettingsAppModel.with(string schema_id, string schema_key) {
			Object(schema_id: schema_id, schema_key: schema_key);
		}

		~SettingsAppModel() {
			this.clear_notify_id();
		}

		public GLib.Object? get_item(uint pos) {
			this.check_init();

			var ids = this._settings.get_strv(this._schema_key);
			if (pos > ids.length) return null;

			return new GLib.DesktopAppInfo(ids[pos]);
		}

		public GLib.Type get_item_type() {
			return typeof (GLib.AppInfo);
		}

		public uint get_n_items() {
			this.check_init();
			return this._settings.get_strv(this._schema_key).length;
		}

		private void set_notify_id() {
			if (this._settings != null && this._notify_id == 0) {
				this._notify_id = this._settings.changed.connect((key) => {
					if (key == this._schema_key) {
						var old_len = this._length;
						var new_len = this._settings.get_strv(this._schema_key).length;

						this._length = new_len;
						this.items_changed(0, old_len, 0);
						this.items_changed(0, new_len, 0);
					}
				});
			}
		}

		private void clear_notify_id() {
			if (this._settings != null && this._notify_id > 0) {
				this._settings.disconnect(this._notify_id);
				this._notify_id = 0;
			}
		}

		private void check_init() {
			if (this._schema_id == null) this._schema_id = "com.expidus.genesis.desktop";
			if (this._schema_key == null) this._schema_key = "favorite-applications";

			if (this._settings == null) {
				this._settings = new GLib.Settings(this._schema_id);
			}

			this.set_notify_id();
		}
	}
}