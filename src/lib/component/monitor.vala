namespace GenesisComponent {
	public class Monitor : GenesisCommon.Monitor {
		private string _name;
		private GenesisCommon.MonitorClient _client;

		public override string name {
			owned get {
				return this._name;
			}
		}

		public override int physical_width {
			get {
				return this._client.physical_width;
			}
		}

		public override int physical_height {
			get {
				return this._client.physical_height;
			}
		}

		public override Gdk.Rectangle geometry {
			get {
				Gdk.Rectangle rect = { 0, 0, 0, 0 };
				try {
					if (this._client != null) this._client.get_geometry(out rect.x, out rect.y, out rect.width, out rect.height);
				} catch (GLib.Error e) {}
				return rect;
			}
		}

		public override string[] layout_names {
			owned get {
				if (this._client == null) return {};
				return this._client.layout_names;
			}
		}

		public override string[] layout_overrides {
			owned get {
				if (this._client == null) return {};
				return this._client.layout_overrides;
			}
			set {
				this._client.layout_overrides = value;
			}
		}

		public Monitor(string name) {
			Object();

			this._name = name;
		}

		public override bool init(GenesisCommon.Shell shell) throws GLib.Error {
			if (base.init(shell)) {
				this._client = shell.dbus_connection.get_proxy_sync("com.expidus.genesis.Shell", "/com/expidus/genesis/shell/monitor/%s".printf(GenesisCommon.Monitor.fix_name(this.name)));
				this._client.layout_attached.connect((layout_name) => this.layout_attached(layout_name));
				this._client.layout_detached.connect((layout_name) => this.layout_detached(layout_name));
				return true;
			}
			return false;
		}

		public override GenesisCommon.Layout? find_layout_provides(GenesisCommon.LayoutFlags flags) {
			if (this.shell == null) return null;

			foreach (var layout_name in this.layout_overrides) {
				var layout = this.shell.get_layout_from_name(layout_name);
				if (layout == null) {
					continue;
				}

				if ((layout.flags & flags) == flags) {
					return layout;
				}
			}

			foreach (var layout_name in this.layout_names) {
				var layout = this.shell.get_layout_from_name(layout_name);
				if (layout == null) {
					continue;
				}

				if ((layout.flags & flags) == flags) {
					return layout;
				}
			}
			return null;
		}
	}
}