namespace GenesisShell {
	public class PkAgent : PolkitAgent.Listener {
		public GenesisWidgets.Application application { get; construct; }

		public PkAgent(GenesisWidgets.Application application) {
			Object(application: application);
		}

		public override async bool initiate_authentication(string action_id, string message, string icon_name, Polkit.Details details, string cookie, GLib.List<Polkit.Identity> identities, GLib.Cancellable? cancellable) throws GLib.Error {
			Gdk.Display? display = null;

			try {
				var pid = int.parse(details.lookup("polkit.subject-pid"));

				string envstr;
				size_t len;
				GLib.FileUtils.get_contents("/proc/%d/environ".printf(pid), out envstr, out len);

				GLib.HashTable<string, string> env = new GLib.HashTable<string, string>(GLib.str_hash, GLib.str_equal);
				var i = 0;

				while (i < len) {
					var entry = envstr.offset(i);

					var key = entry.substring(0, entry.index_of("="));
					var value = entry.substring(entry.index_of("=") + 1);
					env.insert(key, value);

					i += entry.length + 1;
				}

				if (env.contains("WAYLAND_DISPLAY")) {
					var wl_disp = env.get("WAYLAND_DISPLAY");

					GLib.debug("Opening Wayland Display %s", wl_disp);
					display = Gdk.Display.open(wl_disp);
				}
			} catch (GLib.Error e) {
				GLib.warning("Failed to read calling process's environmental variables for display (%s:%d): %s", e.domain.to_string(), e.code, e.message);
				display = Gdk.Display.get_default();
			}

			try {
				if (display == null) throw new Polkit.Error.FAILED("No display was found");

				var seat = display.get_default_seat();

				GenesisCommon.Monitor? monitor = null;
				if (Gdk.SeatCapabilities.POINTER in seat.get_capabilities()) {
					var pointer = seat.get_pointer();

					Gdk.Screen screen;
					int x;
					int y;
					pointer.get_position(out screen, out x, out y);

					monitor = this.application.shell.find_monitor_for_point(x, y);
				}

				if (monitor == null) throw new Polkit.Error.FAILED("No monitor is available");

				var layout = monitor.find_layout_provides(GenesisCommon.LayoutFlags.POLKIT_DIALOG);
				if (layout == null) throw new Polkit.Error.FAILED("No dialog is provided by any layouts on the monitor \"%s\"", monitor.name);

				var dialog = layout.get_polkit_dialog(monitor, action_id, message, icon_name, cookie, cancellable);
				if (dialog == null) throw new Polkit.Error.FAILED("No dialog was created");

				dialog.done.connect(() => {
					this.initiate_authentication.callback();
				});

				if (identities == null) return false;

				dialog.set_from_identities(identities);
				dialog.show();
				yield;

				dialog.destroy();

				if (dialog.is_cancelled) throw new Polkit.Error.CANCELLED("Authentication dialog was closed by the user");
				return true;
			} catch (GLib.Error e) {
				GLib.warning("Polkit dialog error (%s:%d): %s", e.domain.to_string(), e.code, e.message);
				throw e;
			}
		}
	}
}