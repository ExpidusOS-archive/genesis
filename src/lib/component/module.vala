namespace GenesisComponent {
	public abstract class Module : GLib.Object, GenesisCommon.Module {
		[DBus(visible = false)]
		public abstract GLib.Object object { owned get; construct; }

		[DBus(visible = false)]
		public GenesisCommon.Shell get_shell() {
			return (Shell)this.object;
		}
	}
}