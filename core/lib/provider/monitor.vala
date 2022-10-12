namespace GenesisShell {
  internal sealed class MonitorProvider : GLib.Object, IMonitorProvider {
    private ulong _added_id;
    private ulong _removed_id;

    public Context context { get; construct; }

    internal MonitorProvider(Context context) {
      Object(context: context);
    }

    ~MonitorProvider() {
      if (this._added_id > 0) {
        this.context.disconnect(this._added_id);
        this._added_id = 0;
      }

      if (this._removed_id > 0) {
        this.context.disconnect(this._removed_id);
        this._removed_id = 0;
      }
    }

    construct {
      this._added_id = this.context.plugin_added.connect((info, plugin) => {
        var monitor_provider = plugin.container.get(typeof (IMonitorProvider)) as IMonitorProvider;
        if (monitor_provider != null) {
          monitor_provider.added.connect((id) => this.added(id));
          foreach (var id in monitor_provider.get_monitor_ids()) {
            unowned var monitor = monitor_provider.get_monitor(id);
            if (monitor == null) continue;
            this.added(monitor);
          }
        }
      });

      this._removed_id = this.context.plugin_removed.connect((info, plugin) => {
        var monitor_provider = plugin.container.get(typeof (IMonitorProvider)) as IMonitorProvider;
        if (monitor_provider != null) {
          monitor_provider.removed.connect((id) => this.removed(id));
          foreach (var id in monitor_provider.get_monitor_ids()) {
            unowned var monitor = monitor_provider.get_monitor(id);
            if (monitor == null) continue;
            this.removed(monitor);
          }
        }
      });
    }

    public Monitor? create_virtual_monitor() {
      foreach (var plugin in this.context.plugins.get_values()) {
        var monitor_provider = plugin.container.get(typeof (IMonitorProvider)) as IMonitorProvider;
        if (monitor_provider == null) continue;

        var virt_monitor = monitor_provider.create_virtual_monitor();
        if (virt_monitor == null) continue;
        return virt_monitor;
      }
      return null;
    }

    public unowned Monitor? get_monitor(string id) {
      foreach (var plugin in this.context.plugins.get_values()) {
        var monitor_provider = plugin.container.get(typeof (IMonitorProvider)) as IMonitorProvider;
        if (monitor_provider == null) continue;

        unowned var monitor = monitor_provider.get_monitor(id);
        if (monitor == null) continue;
        return monitor;
      }
      return null;
    }

    public GLib.List<string> get_monitor_ids() {
      var list = new GLib.List<string>();
      foreach (var plugin in this.context.plugins.get_values()) {
        var monitor_provider = plugin.container.get(typeof (IMonitorProvider)) as IMonitorProvider;
        if (monitor_provider == null) continue;

        var sublist = monitor_provider.get_monitor_ids();
        foreach (var id in sublist) {
          if (list.find_custom(id, GLib.strcmp) != null) continue;

          list.append(id);
        }
      }
      return list;
    }

    public unowned Monitor? get_primary_monitor() {
      foreach (var plugin in this.context.plugins.get_values()) {
        var monitor_provider = plugin.container.get(typeof (IMonitorProvider)) as IMonitorProvider;
        if (monitor_provider == null) continue;

        unowned var monitor = monitor_provider.get_primary_monitor();
        if (monitor == null) continue;
        return monitor;
      }
      return null;
    }
  }
}
