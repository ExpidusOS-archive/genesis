namespace GenesisShell {
	[DBus(name = "com.expidus.genesis.Window")]
	public abstract class Window : GenesisCommon.Window {
		private string? _layout_name;
		private WindowLayout? _window_layout;
		private uint _obj_id;

		public string? layout_name {
			get {
				var monitor = this.shell.find_monitor(this.monitor_name) as Monitor;
				if (monitor == null) return this._layout_name == null ? "" : this._layout_name;

				var layout = monitor.find_layout_provides(GenesisCommon.LayoutFlags.WINDOW_DECORATION);
				if (layout == null) return this._layout_name == null ? "" : this._layout_name;

				var is_null = this._layout_name == null;
				if (is_null || this._layout_name != layout.name) {
					this._layout_name = layout.name;

					if (!is_null) this._window_layout = null;
				}
				return this._layout_name == null ? "" : this._layout_name;
			}
		}

		[DBus(visible = false)]
		public WindowLayout? window_layout {
			get {
				var layout_name = this.layout_name;
				if (layout_name == null || layout_name == "") return this._window_layout;

				var layout = this.shell.get_layout_from_name(layout_name) as Layout;
				if (layout == null) return this._window_layout;

				if (this._window_layout == null) this._window_layout = layout.get_window_layout(this);
				return this._window_layout;
			}
		}

		~Window() {
		}

		[DBus(visible = false)]
		public void destroy() {
			if (this._obj_id > 0) {
				this.shell.dbus_connection.unregister_object(this._obj_id);
				this._obj_id = 0;
			}
		}

		[DBus(visible = false)]
		public override bool init(GenesisCommon.Shell shell) throws GLib.Error {
			if (!base.init(shell)) return false;

			this._obj_id = this.shell.dbus_connection.register_object("/com/expidus/genesis/shell/window/%s".printf(this.to_string().down().replace("-", "").replace(" ", "")), (GenesisCommon.Window)this);
			return true;
		}

		[DBus(visible = false)]
		public virtual string to_string() {
			return "%p".printf(this);
		}

		[DBus(name = "ToString")]
		public string to_string_dbus() throws GLib.Error {
			return this.to_string();
		}
	}
}