namespace Genesis {
	public class LauncherAppModel : GLib.Object, GLib.ListModel {
		private uint _length;
		private GLib.AppInfoMonitor _monitor;
		private ulong _changed_id;

		construct {
			this._length = 0;
			this._monitor = GLib.AppInfoMonitor.@get();
			this._changed_id = this._monitor.changed.connect(() => {
				var old_len = this._length;
				var new_len = this.get_n_items();
				this.items_changed(0, old_len, 0);
				this.items_changed(0, 0, new_len);
			});
		}

		~LauncherAppModel() {
			this._monitor.disconnect(this._changed_id);
		}

		public GLib.Object? get_item(uint pos) {
			return this.get_all().nth_data(pos);
		}

		public GLib.Type get_item_type() {
			return typeof (GLib.AppInfo);
		}

		public uint get_n_items() {
			return this.get_all().length();
		}

		private GLib.List<GLib.AppInfo> get_all() {
			var apps = GLib.AppInfo.get_all();
			var ret = new GLib.List<GLib.AppInfo>();
			foreach (var app in apps) {
				if (app.should_show()) ret.append(app);
			}
			ret.sort((_a, _b) => {
				var a = _a.get_display_name();
				var b = _b.get_display_name();
				return GLib.strcmp(a, b);
			});
			return ret;
		}
	}
}