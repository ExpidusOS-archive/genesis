namespace ExpidusDesktop {
  [GtkTemplate(ui = "/com/expidus/genesis/module/expidus-desktop/apps.glade")]
  public class ApplicationLauncher : GenesisWidgets.LayerWindow {
    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;

    [GtkChild]
    private unowned Gtk.FlowBox search_results;
    
    public ApplicationLauncher(GenesisComponent.Monitor monitor) {
      Object(application: monitor.shell.application, monitor_name: monitor.name, layer: GtkLayerShell.Layer.TOP);
    }

    construct {
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);

      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.TOP, 8);
      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 8);
      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 8);

      GtkLayerShell.set_keyboard_mode(this, GtkLayerShell.KeyboardMode.EXCLUSIVE);

      this.search_results.set_sort_func((a, b) => {
        var ai_a = a.get_child() as GenesisWidgets.ApplicationIcon;
        var ai_b = b.get_child() as GenesisWidgets.ApplicationIcon;
        return ai_a.label.ascii_casecmp(ai_b.label);
      });
      this.search_results.set_filter_func((row) => {
        var ai = row.get_child() as GenesisWidgets.ApplicationIcon;
        return ai.label.down().contains(this.search_entry.get_text());
      });

      var apps = GLib.AppInfo.get_all();
      foreach (var app in apps) {
        if (app.should_show()) {
          var w = new GenesisWidgets.ApplicationIcon.for_appinfo(app);
          this.search_results.add(w);
          w.clicked.connect(() => {
            try {
              ((GenesisWidgets.Application)this.application).shell.close_ui(this.monitor_name, GenesisCommon.UIElement.APPS);
            } catch (GLib.Error e) {}
          });
        }
      }
    }
    
    [GtkCallback]
    private void do_search_changed() {
      this.search_results.invalidate_filter();
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