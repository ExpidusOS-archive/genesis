namespace ExpidusMobile {
	public class ShellModule : GenesisShell.Module, Peas.Activatable {
		private GenesisShell.Shell _shell;

		public override GLib.Object object {
			owned get {
				return this._shell;
			}
			construct {
				var shell = value as GenesisShell.Shell;
				assert(shell != null);
				this._shell = shell;
			}
		}

		public void activate() {
			var shell = this.get_shell();

			try {
				shell.define_layout(this, new ShellLayout());
			} catch (GLib.Error e) {
				GLib.error("Failed to register layout (%s:%d): %s", e.domain.to_string(), e.code, e.message);
			}
		}

		public void deactivate() {}

		public void update_state() {}
	}

	public class ComponentModule : GenesisComponent.Module, Peas.Activatable {
		private GenesisComponent.Shell _shell;

		public override GLib.Object object {
			owned get {
				return this._shell;
			}
			construct {
				var shell = value as GenesisComponent.Shell;
				assert(shell != null);
				this._shell = shell;
			}
		}

		public void activate() {
			var shell = this.get_shell();

			try {
				shell.define_layout(this, new ComponentLayout());
			} catch (GLib.Error e) {
				GLib.error("Failed to register layout (%s:%d): %s", e.domain.to_string(), e.code, e.message);
			}
		}

		public void deactivate() {}

		public void update_state() {}
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module) {
	var obj_module = module as Peas.ObjectModule;
	obj_module.register_extension_type(typeof (GenesisShell.Module), typeof (ExpidusMobile.ShellModule));
	obj_module.register_extension_type(typeof (GenesisComponent.Module), typeof (ExpidusMobile.ComponentModule));
}