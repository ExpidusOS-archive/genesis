private static bool arg_components = false;
private static bool arg_ssd = false;
private static bool arg_no_shell = false;
private static bool arg_debug = false;
private static bool arg_version = false;
private GLib.Pid wf_pid;
private GLib.File tmp_config;

private const GLib.OptionEntry[] options = {
	{ "components-only", 'c', GLib.OptionFlags.NONE, GLib.OptionArg.NONE, ref arg_components, "Only run the component side of things", null },
	{ "server-side-decoration", 's', GLib.OptionFlags.NONE, GLib.OptionArg.NONE, ref arg_ssd, "Enables server side decorations on windows", null },
	{ "no-shell", 'h', GLib.OptionFlags.NONE, GLib.OptionArg.NONE, ref arg_no_shell, "Prevents the components from loading, useful for testing", null },
	{ "debug", 'd', GLib.OptionFlags.NONE, GLib.OptionArg.NONE, ref arg_debug, "Enables debug messages for Wayfire", null },
	{ "version", 'v', GLib.OptionFlags.NONE, GLib.OptionArg.NONE, ref arg_version, "Prints the version string", null },
	{ null }
};

private void handle_exit(int sig) {
	try {
		tmp_config.@delete();
	} catch (GLib.Error e) {
		stderr.printf("Failed to delete temp config (%s:%d): %s\n",e.domain.to_string(), e.code, e.message);
	}
	if (wf_pid == 0) Posix.kill(wf_pid, sig);
	GLib.Process.exit(sig);
}

namespace GenesisShell {
	public class CApplication : GenesisWidgets.Application {
		private GLib.HashTable<string, Desktop> _desktops;
		private PkAgent _pk_agent;

		construct {
			this._desktops = new GLib.HashTable<string, Desktop>(GLib.str_hash, GLib.str_equal);
			this._pk_agent = new PkAgent(this);
		}

		public CApplication() {
			Object(application_id: "com.expidus.genesis.ComponentShell", resource_base_path: "/com/expidus/genesis/component", shell_instance_type: GenesisCommon.ShellInstanceType.COMPONENT);
		}

		public override void activate() {
			base.activate();

			foreach (var monitor_name in this.shell.monitors) {
				this._desktops.set(monitor_name, new Desktop(this, monitor_name));
			}

			try {
				var subject = Polkit.UnixSession.new_for_process_sync(Posix.getpid(), null);
				this._pk_agent.register(PolkitAgent.RegisterFlags.NONE, subject, null);
			} catch (GLib.Error e) {
				GLib.warning("Failed to initialize the Polkit agent (%s:%d): %s", e.domain.to_string(), e.code, e.message);
			}
		}
	}
}

int main(string[] args) {
	try {
		var opctx = new GLib.OptionContext(_("- Genesis Shell"));
		opctx.set_help_enabled(true);
		opctx.add_main_entries(options, null);
		opctx.parse(ref args);
	} catch (GLib.Error e) {
		stderr.printf("%s: Failed to parse arguments (%s:%d): %s\n", GLib.Path.get_basename(args[0]), e.domain.to_string(), e.code, e.message);
		return 1;
	}

	if (arg_version) {
		stdout.printf("%s\n", GenesisCommon.VERSION);
		return 0;
	}

	if (arg_components) {
		GenesisWidgets.init(ref args);
		return new GenesisShell.CApplication().run(args);
	}

	try {
		GLib.FileIOStream tmp_config_stream;
		tmp_config = GLib.File.new_tmp("genesis-shell.XXXXXX.ini", out tmp_config_stream);

		GLib.Process.@signal(GLib.ProcessSignal.ABRT, handle_exit);
		GLib.Process.@signal(GLib.ProcessSignal.KILL, handle_exit);
		GLib.Process.@signal(GLib.ProcessSignal.HUP, handle_exit);
		GLib.Process.@signal(GLib.ProcessSignal.QUIT, handle_exit);
		GLib.Process.@signal(GLib.ProcessSignal.TERM, handle_exit);

		GLib.debug("Using configuration for Wayfire as \"%s\"", tmp_config.get_path());

		var dos = new GLib.DataOutputStream(tmp_config_stream.output_stream);
		dos.put_string("[core]\n");
		dos.put_string("plugins = glib-main-loop genesis-shell-wayfire autostart\n");

		if (arg_ssd) dos.put_string("preferred_decoration_mode = server\n");
		else dos.put_string("preferred_decoration_mode = client\n");

		dos.put_string("\n");

		dos.put_string("[autostart]\n");
		dos.put_string("autostart_wf_shell = false\n");
		dos.put_string("pulse = pipewire\n");
		dos.put_string("portal_update = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKOP=Genesis\n");
		dos.put_string("portal = /usr/libexec/xdg-desktop-portal\n");
		dos.put_string("ibus = ibus-daemon -dr\n");
		if (!arg_no_shell) dos.put_string("shell = GDK_BACKEND=wayland " + args[0] + " -c");

		string[] wf_args = { "wayfire", "-c", tmp_config.get_path() };

		if (arg_debug) wf_args += "-d";

		GLib.Process.spawn_sync(null, wf_args, null, GLib.SpawnFlags.SEARCH_PATH, null);
	} catch (GLib.Error e) {
		stderr.printf("%s: Failed to launch (%s:%d): %s\n", GLib.Path.get_basename(args[0]), e.domain.to_string(), e.code, e.message);
		return 1;
	}
	return 0;
}