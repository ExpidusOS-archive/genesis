int main(string[] args) {
	var loop = new GLib.MainLoop();

	GLib.Bus.own_name(GLib.BusType.SESSION, "org.freedesktop.impl.portal.desktop.genesis", GLib.BusNameOwnerFlags.NONE, () => {}, (conn, name) => {
		GLib.debug("Acquired the name %s", name);
		try {
			conn.register_object("/org/freedesktop/portal/desktop", new GenesisPortal.Settings());
		} catch (GLib.Error e) {
			loop.quit();
			GLib.critical("Failed to register objects (%s:%d): %s", e.domain.to_string(), e.code, e.message);
		}
	}, (conn, name) => {
		GLib.warning("Lost name %s", name);
		loop.quit();
	});

	loop.run();
	return 0;
}