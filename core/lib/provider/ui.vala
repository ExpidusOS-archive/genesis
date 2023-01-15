namespace GenesisShell {
  internal class UIProvider : GLib.Object, IUIProvider {
    public Context context { get; construct; }

    internal UIProvider(Context context) {
      Object(context: context);
    }

    public GLib.List <string> monitor_list_ids_for_kind(Monitor monitor, UIElementKind kind) {
      var list = new GLib.List <string>();

      foreach (var plugin in this.context.plugins.get_values()) {
        var ui_provider = plugin.container.get(typeof(IUIProvider)) as IUIProvider;
        if (ui_provider == null) {
          continue;
        }

        var sublist = ui_provider.monitor_list_ids_for_kind(monitor, kind);
        foreach (var item in sublist) {
          if (list.find(item) != null) {
            continue;
          }
          list.append(item);
        }
      }
      return list;
    }

    public IUIElement ? for_monitor(Monitor monitor, UIElementKind kind, string ?id) {
      foreach (var plugin in this.context.plugins.get_values()) {
        var ui_provider = plugin.container.get(typeof(IUIProvider)) as IUIProvider;
        if (ui_provider == null) {
          continue;
        }

        var elem = ui_provider.for_monitor(monitor, kind, id);
        if (elem == null) {
          continue;
        }
        return elem;
      }
      return null;
    }

    public override GLib.Value? action(UIElementKind elem, UIActionKind action, string[] names, GLib.Value[] values) {
      foreach (var plugin in this.context.plugins.get_values()) {
        var ui_provider = plugin.container.get(typeof(IUIProvider)) as IUIProvider;
        if (ui_provider == null) {
          continue;
        }

        var result = ui_provider.action(elem, action, names, values);
        if (result == null) {
          continue;
        }
        return elem;
      }

      var value = GLib.Value(GLib.Type.BOOLEAN);
      value.set_boolean(false);
      return value;
    }
  }
}
