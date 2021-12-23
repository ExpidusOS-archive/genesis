namespace GenesisWidgets {
	public class LayerWindow : Hdy.Window {
		public string monitor_name { get; set construct; }
		public GtkLayerShell.Layer layer { get; set construct; }

		public Gdk.Monitor? monitor {
			owned get {
				var application = this.application as Application;
				if (application == null) return null;
				if (application.shell == null) return null;

				var monitor = application.shell.find_monitor(this.monitor_name);
				if (monitor == null) return null;

				return this.get_display().get_monitor_at_point(monitor.geometry.x, monitor.geometry.y);
			}
		}

		construct {
			GtkLayerShell.init_for_window(this);
			GtkLayerShell.set_layer(this, this.layer);
			if (this.monitor_name != null && this.monitor != null) GtkLayerShell.set_monitor(this, this.monitor);

			this.notify["layer"].connect(() => {
				GtkLayerShell.set_layer(this, this.layer);
			});

			this.notify["monitor_name"].connect(() => {
				if (this.monitor_name != null && this.monitor != null) GtkLayerShell.set_monitor(this, this.monitor);
			});
		}
	}
}