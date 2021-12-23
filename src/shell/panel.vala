namespace GenesisShell {
	public class Panel : GenesisWidgets.LayerWindow {
		public GenesisCommon.PanelLayout layout { get; construct; }

		public Panel(owned GenesisCommon.PanelLayout layout) {
			Object(layout: layout, monitor_name: layout.monitor_name, layer: GtkLayerShell.Layer.BOTTOM);

			GtkLayerShell.auto_exclusive_zone_enable(this);
			GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, GenesisCommon.PanelAnchor.LEFT in layout.anchor);
			GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.RIGHT, GenesisCommon.PanelAnchor.RIGHT in layout.anchor);
			GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, GenesisCommon.PanelAnchor.TOP in layout.anchor);
			GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, GenesisCommon.PanelAnchor.BOTTOM in layout.anchor);

			this.layout.attach(this);
			this.show_all();
		}

		~Panel() {
			if (this.layout != null) {
				this.layout.detach(this);
				this._layout = null;
			}
		}

		public override void get_preferred_width(out int min_width, out int nat_width) {
			var layout = this.layout;
			if (layout != null) min_width = nat_width = layout.geometry.width;
			else min_width = nat_width = 0;
		}

		public override void get_preferred_height(out int min_height, out int nat_height) {
			var layout = this.layout;
			if (layout != null) min_height = nat_height = this.layout.geometry.height;
			else min_height = nat_height = 0;
		}

		public override bool draw(Cairo.Context cr) {
			base.draw(cr);

			var layout = this.layout;
			if (layout == null) return false;

			layout.draw(cr);
			return true;
		}
	}
}