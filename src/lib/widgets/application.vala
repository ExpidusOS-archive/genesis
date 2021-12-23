namespace GenesisWidgets {
	public class Application : Gtk.Application {
		private GenesisCommon.Shell? _shell;
		private GenesisCommon.ShellInstanceType _shell_instance_type;

		public GenesisCommon.Shell? shell {
			get {
				return this._shell;
			}
			set construct {
				this._shell = value;
				// TODO: signal every window to update
			}
		}

		public GenesisCommon.ShellInstanceType shell_instance_type {
			get {
				if (this.shell != null) {
					return this.shell.instance_type;
				}

				if (this._shell_instance_type == GenesisCommon.ShellInstanceType.NONE) {
					return GenesisWidgets._shell_instance_type;
				}
				
				return this._shell_instance_type;
			}
			set construct {
				this._shell_instance_type = value;
			}
		}

		public override void startup() {
			base.startup();

			if (this.shell == null) {
				switch (this.shell_instance_type) {
					case GenesisCommon.ShellInstanceType.WM:
						this.shell = new GenesisShell.Shell.with_dbus_connection(this.get_dbus_connection());
						break;
					case GenesisCommon.ShellInstanceType.COMPONENT:
						this.shell = new GenesisComponent.Shell.with_dbus_connection(this.get_dbus_connection());
						break;
					default:
						GLib.debug("Not creating a shell instance");
						break;
				}

				if (this.shell != null && this.shell is GLib.Initable) {
					try {
						((GLib.Initable)this.shell).init();
					} catch (GLib.Error e) {
						GLib.critical("Failed to inititalize the shell (%s:%d): %s", e.domain.to_string(), e.code, e.message);
					}
				}
			}

			try {
				this.shell.rescan_modules();
			} catch (GLib.Error e) {
				GLib.critical("Failed to scan modules for the shell (%s:%d): %s", e.domain.to_string(), e.code, e.message);
			}
		}
	}
}