namespace GenesisWidgets {
	private bool _is_inited = false;
	private GenesisCommon.ShellInstanceType _shell_instance_type = GenesisCommon.ShellInstanceType.NONE;

	public void init(ref weak string[]? args, GenesisCommon.ShellInstanceType? shell_instance_type = GenesisCommon.ShellInstanceType.NONE) {
		if (_is_inited) {
			GLib.warning("Genesis Widgets is already initialized");
			return;
		}

		_is_inited = true;
		_shell_instance_type = shell_instance_type;

		Gdk.set_allowed_backends("wayland");
		Gtk.init(ref args);
		Hdy.init();
	}
}