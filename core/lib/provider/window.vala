namespace GenesisShell {
  internal sealed class WindowProvider : GLib.Object, IWindowProvider {
    public Context context { get; construct; }

    internal WindowProvider(Context context) {
      Object(context: context);
    }

    public unowned Window ? get_window(WindowID id) {
      foreach (var plugin in this.context.plugins.get_values()) {
        var window_provider = plugin.container.get(typeof(IWindowProvider)) as IWindowProvider;
        if (window_provider == null) {
          continue;
        }

        unowned var window = window_provider.get_window(id);
        if (window == null) {
          continue;
        }
        return window;
      }
      return null;
    }

    public GLib.List <WindowID ?> get_window_ids() {
      var list = new GLib.List <WindowID ?>();
      foreach (var plugin in this.context.plugins.get_values()) {
        var window_provider = plugin.container.get(typeof(IWindowProvider)) as IWindowProvider;
        if (window_provider == null) {
          continue;
        }

        var sublist = window_provider.get_window_ids();
        foreach (var id in sublist) {
          if (list.find(id) != null) {
            continue;
          }

          list.append(id);
        }
      }
      return list;
    }
  }
}
