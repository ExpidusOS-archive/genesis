namespace ExpidusDesktop {
  public class ApplicationLauncher : GenesisWidgets.LayerWindow {
    public ApplicationLauncher(GenesisComponent.Monitor monitor) {
      Object(application: monitor.shell.application, monitor_name: monitor.name, layer: GtkLayerShell.Layer.TOP);
    }

    construct {
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);

      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.TOP, 8);
      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 8);
      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 15);
    }
    
    public override void realize() {
      base.realize();
    }

		public override void get_preferred_width(out int min_width, out int nat_width) {
			min_width = nat_width = ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(350);
		}

		public override void get_preferred_height(out int min_height, out int nat_height) {
			min_height = nat_height = this.monitor.geometry.height - ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(5)
        - ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(35);
		}
  }
}