namespace GenesisShell {
  public abstract class WindowManager : GLib.Object {
    private GLib.List<Monitor> _monitors;
    private GLib.List<Workspace> _workspaces;

    public Context context { get; construct; }

    public GLib.List<weak Monitor> monitors {
      owned get {
        return this._monitors.copy();
      }
    }

    public GLib.List<weak Workspace> workspaces {
      owned get {
        return this._workspaces.copy();
      }
    }

    public void add_monitor(Monitor monitor) {
      if (!this.has_monitor(monitor)) {
        this._monitors.append(monitor);
        this.monitor_added(monitor);
      }
    }

    public void remove_monitor(Monitor monitor) {
      unowned var item = this._monitors.find_custom(monitor, GLib.strcmp);
      if (item != null) {
        this._monitors.remove_link(item);
        this.monitor_removed(monitor);
      }
    }

    public bool has_monitor(Monitor monitor) {
      unowned var item = this._monitors.find_custom(monitor, GLib.strcmp);
      return item != null;
    }

    public void add_workspace(Workspace workspace) {
      if (!this.has_workspace(workspace)) {
        this._workspaces.append(workspace);
        this.workspace_added(workspace);
      }
    }

    public void remove_workspace(Workspace workspace) {
      unowned var item = this._workspaces.find_custom(workspace, (a, b) => (int)(a.id > b.id) - (int)(a.id < b.id));
      if (item != null) {
        this._workspaces.remove_link(item);
        this.workspace_added(workspace);
      }
    }

    public bool has_workspace(Workspace workspace) {
      unowned var item = this._workspaces.find_custom(workspace, (a, b) => (int)(a.id > b.id) - (int)(a.id < b.id));
      return item != null;
    }

    public abstract void manage(Window window);
    public abstract void unmanage(Window window);

    public signal void monitor_added(Monitor monitor);
    public signal void monitor_removed(Monitor monitor);

    public signal void workspace_added(Workspace workspace);
    public signal void workspace_removed(Workspace workspace);
  }
}
