namespace GenesisShellGtk3 {
  public class UIProvider : GLib.Object, GenesisShell.IUIProvider {
    public override GenesisShell.Context context {
      get {
        return this.plugin.context;
      }
      construct {}
    }

    public Plugin plugin { get; construct; }

    internal UIProvider(Plugin plugin) {
      Object(plugin: plugin);
    }

    public GLib.List <string> monitor_list_ids_for_kind(GenesisShell.Monitor monitor, GenesisShell.UIElementKind kind) {
      var list = new GLib.List <string>();

      var gtk_monitor = monitor as Monitor;
      if (gtk_monitor != null) {
        switch (kind) {
        case GenesisShell.UIElementKind.DESKTOP:
          list.append("desktop");
          break;

        case GenesisShell.UIElementKind.PANEL:
          list.append("panel");
          break;

        case GenesisShell.UIElementKind.DASH:
          list.append("dashboard");
          break;

        default:
          break;
        }
        return list;
      }
      return list;
    }

    public GenesisShell.IUIElement ?for_monitor(GenesisShell.Monitor monitor, GenesisShell.UIElementKind kind, string ?id) {
      var gtk_monitor = monitor as Monitor;
      if (gtk_monitor != null) {
        switch (kind) {
        case GenesisShell.UIElementKind.DESKTOP:
          return gtk_monitor.desktop.widget;
        case GenesisShell.UIElementKind.PANEL:
          return gtk_monitor.panel_widget;
        case GenesisShell.UIElementKind.DASH:
          return gtk_monitor.dash_widget;
        default:
          break;
        }
      }
      return null;
    }

    public override GLib.Value? action(GenesisShell.UIElementKind elem, GenesisShell.UIActionKind action, string[] names, GLib.Value[] values) {
      switch (elem) {
        case GenesisShell.UIElementKind.APPS:
        case GenesisShell.UIElementKind.DASH:
          for (var i = 0; i < names.length; i++) {
            var name = names[i];
            var value = values[i];

            if (name == "monitor") {
              var monitor = value.get_object() as Monitor;
              if (monitor == null) continue;
              return monitor.action(elem, action, names, values);
            }
          }
          break;
      }

      var value = GLib.Value(GLib.Type.BOOLEAN);
      value.set_boolean(false);
      return value;
    }
  }
}
