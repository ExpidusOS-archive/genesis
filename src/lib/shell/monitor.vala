namespace GenesisShell {
	[DBus(name = "com.expidus.genesis.Monitor")]
	public abstract class Monitor : GenesisCommon.Monitor {
		private uint _obj_id;
		private GLib.List<string> _layouts;

		public override int physical_width {
			get {
				int value;
				this.get_physical_size(out value, null);
				return value;
			}
		}

		public override int physical_height {
			get {
				int value;
				this.get_physical_size(null, out value);
				return value;
			}
		}

		public override string[] layout_names {
			owned get {
				string[] names = {};
				foreach (var n in this._layouts) names += n;
				return names;
			}
		}

		public override string[] layout_overrides {
			owned get {
				return ((Shell)this.shell).get_layout_overrides_for_monitor(this.name);
			}
			set {
				((Shell)this.shell).set_layout_overrides_for_monitor(this.name, value);
			}
		}

		construct {
			this._layouts = new GLib.List<string>();
			this.notify.connect(() => this.updated());
		}

		[DBus(visible = false)]
		public void destroy() {
			if (this._obj_id > 0) {
				this.shell.dbus_connection.unregister_object(this._obj_id);
				this._obj_id = 0;
			}
		}

		[DBus(visible = false)]
		public override void attach_layout(GenesisCommon.Module _module, GenesisCommon.Layout _layout) throws GenesisCommon.ShellError {
			var module = _module as Module;
			if (module == null) throw new GenesisCommon.ShellError.INVALID_MODULE("Module is not a shell type module");

			var layout = _layout as Layout;
			if (layout == null) throw new GenesisCommon.ShellError.INVALID_MODULE("Layout is not a shell type layout");

			if (this.shell == null) throw new GenesisCommon.ShellError.INVALID_SHELL("Requires a shell instance");

			string name;
			if (!this.shell.check_module(module, out name)) throw new GenesisCommon.ShellError.INVALID_MODULE("Failed to check module authenticity");

			var l = this.shell.get_layout_from_name(layout.name);
			if (l == null) throw new GenesisCommon.ShellError.INVALID_LAYOUT("Requires a layout to be registered");

			if (this.shell.get_module_for_layout(layout) != module) throw new GenesisCommon.ShellError.INVALID_MODULE("Module does not own the layout");
			if (layout.name in this.layout_names) return;

			this._layouts.append(layout.name);
			this.notify_property("layout-names");

			GLib.debug("Applied layout \"%s\" to monitor \"%s\"", layout.name, this.name);

			this.layout_attached(layout.name);
			this.updated();
		}

		[DBus(visible = false)]
		public override void detach_layout(GenesisCommon.Module _module, GenesisCommon.Layout _layout) throws GenesisCommon.ShellError {
			var module = _module as Module;
			if (module == null) throw new GenesisCommon.ShellError.INVALID_MODULE("Module is not a shell type module");

			var layout = _layout as Layout;
			if (layout == null) throw new GenesisCommon.ShellError.INVALID_MODULE("Layout is not a shell type layout");

			string name;
			if (!this.shell.check_module(module, out name)) throw new GenesisCommon.ShellError.INVALID_MODULE("Failed to check module authenticity");

			var l = this.shell.get_layout_from_name(layout.name);
			if (l == null) throw new GenesisCommon.ShellError.INVALID_LAYOUT("Requires a layout to be registered");

			if (this.shell.get_module_for_layout(layout) != module) throw new GenesisCommon.ShellError.INVALID_MODULE("Module does not own the layout");
			if (!(layout.name in this.layout_names)) return;

			this._layouts.remove(layout.name);
			this.notify_property("layout-names");

			this.layout_detached(layout.name);
			this.updated();
		}

		[DBus(visible = false)]
		public override GenesisCommon.Layout? find_layout_provides(GenesisCommon.LayoutFlags flags) {
			if (this.shell == null) return null;

			foreach (var layout_name in this.layout_overrides) {
				var layout = this.shell.get_layout_from_name(layout_name) as Layout;
				if (layout == null) {
					this._layouts.remove(layout_name);
					continue;
				}

				if ((layout.flags & flags) == flags) {
					return layout;
				}
			}

			foreach (var layout_name in this._layouts) {
				var layout = this.shell.get_layout_from_name(layout_name) as Layout;
				if (layout == null) {
					this._layouts.remove(layout_name);
					continue;
				}

				if ((layout.flags & flags) == flags) {
					return layout;
				}
			}
			return null;
		}

		[DBus(visible = false)]
		public override bool init(GenesisCommon.Shell shell) throws GLib.Error {
			if (!base.init(shell)) return false;

			this._obj_id = this.shell.dbus_connection.register_object("/com/expidus/genesis/shell/monitor/%s".printf(GenesisCommon.Monitor.fix_name(this.name)), (GenesisCommon.Monitor)this);
			return true;
		}
	}
}