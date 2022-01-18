namespace GenesisWidgets {
	private bool _is_inited = false;
	private GenesisCommon.ShellInstanceType _shell_instance_type = GenesisCommon.ShellInstanceType.NONE;
	
	public extern GLib.Resource get_resource();

	public void init(ref weak string[]? args, GenesisCommon.ShellInstanceType? shell_instance_type = GenesisCommon.ShellInstanceType.NONE) {
		if (_is_inited) {
			GLib.warning("Genesis Widgets is already initialized");
			return;
		}

		_is_inited = true;
		_shell_instance_type = shell_instance_type;

		GLib.resources_register(get_resource());

		Gdk.set_allowed_backends("wayland");
		Gtk.init(ref args);
		Hdy.init();
	}
}