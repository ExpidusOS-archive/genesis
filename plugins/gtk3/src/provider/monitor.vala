namespace GenesisShellGtk3 {
  public sealed class MonitorProvider : GLib.Object, GenesisShell.IMonitorProvider, GLib.Initable {
    private GLib.HashTable<string, Monitor> _monitors;
    private ulong _monitor_added;
    private ulong _monitor_removed;
    private bool _is_init = false;

    public GenesisShell.Context context { get; construct; }
    public Plugin plugin { get; construct; }

    internal MonitorProvider(Plugin plugin, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(context: plugin.context, plugin: plugin);
      this.init(cancellable);
    }

    ~MonitorProvider() {
      if (this._monitor_added > 0) {
        this.plugin.display.disconnect(this._monitor_added);
        this._monitor_added = 0;
      }

      if (this._monitor_removed > 0) {
        this.plugin.display.disconnect(this._monitor_removed);
        this._monitor_removed = 0;
      }
    }

    construct {
      this._monitors = new GLib.HashTable<string, Monitor>(GLib.str_hash, GLib.str_equal);
      this._monitor_added = this.plugin.display.monitor_added.connect((monitor) => {
        try {
          this.add_monitor(monitor);
        } catch (GLib.Error e) {
          GLib.error(N_("Failed to add monitor \"%s\": %s:%d: %s"), Monitor.name_for(monitor), e.domain.to_string(), e.code, e.message);
        }
      });

      this._monitor_removed = this.plugin.display.monitor_removed.connect((monitor) => {
        string name = Monitor.name_for(monitor);
        var obj = this._monitors.get(name);
        if (obj != null) this.removed(obj);
        this._monitors.remove(name);
      });
    }

    public bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

      for (var i = 0; i < this.plugin.display.get_n_monitors(); i++) {
        var monitor = this.plugin.display.get_monitor(i);
        if (monitor == null) continue;

        this.add_monitor(monitor, cancellable);
      }
      return true;
    }

    private void add_monitor(Gdk.Monitor monitor, GLib.Cancellable? cancellable = null) throws GLib.Error {
      string name = Monitor.name_for(monitor);
      if (!this._monitors.contains(name)) {
        var obj = new Monitor(this, monitor);
        this._monitors.set(name, obj);
        this.added(obj);
      }
    }

    public GenesisShell.Monitor? create_virtual_monitor() {
      return null;
    }

    public unowned GenesisShell.Monitor? get_monitor(string id) {
      return this._monitors.get(id);
    }

    public GLib.List<string> get_monitor_ids() {
      var list = new GLib.List<string>();
      for (var i = 0; i < this.plugin.display.get_n_monitors(); i++) {
        var monitor = this.plugin.display.get_monitor(i);
        if (monitor == null) continue;

        list.append(Monitor.name_for(monitor));
      }
      return list;
    }
  }
}
