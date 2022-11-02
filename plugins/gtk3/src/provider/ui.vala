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
        default:
          break;
        }
      }
      return null;
    }
  }
}
