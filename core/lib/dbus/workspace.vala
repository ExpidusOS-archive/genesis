namespace GenesisShell {
  [DBus(name = "com.expidus.genesis.Workspace")]
  public interface IWorkspaceDBus : GLib.Object {
    public abstract string name { owned get; }
    public abstract string[] monitors { owned get; }
    public abstract WorkspaceID id { get; }

    public abstract void add_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError;
    public abstract bool has_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError;
    public abstract void remove_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError;

    public signal void monitor_added(string id);
    public signal void monitor_removed(string id);
  }

  internal class DBusWorkspace : GLib.Object, IWorkspaceDBus, GLib.Initable {
    private bool _is_init = false;
    private uint _obj_id;

    public GLib.DBusConnection connection { get; construct; }
    public Workspace workspace { get; construct; }

    public string name {
      owned get {
        return this.workspace.name;
      }
    }

    public string[] monitors {
      owned get {
        string[] value = {};
        foreach (var monitor in this.workspace.monitors) {
          value += monitor.id;
        }
        return value;
      }
    }

    public WorkspaceID id {
      get {
        return this.workspace.id;
      }
    }

    internal DBusWorkspace(Workspace workspace, GLib.DBusConnection connection, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(workspace: workspace, connection: connection);
      this.init(cancellable);
    }

    internal async DBusWorkspace.make_async_connection(Workspace workspace, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(workspace: workspace, connection: yield GLib.Bus.get(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    internal DBusWorkspace.make_sync_connection(Workspace workspace, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(workspace: workspace, connection: GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    construct {
      this.workspace.monitor_added.connect((ws) => this.monitor_added(ws.id));
      this.workspace.monitor_removed.connect((ws) => this.monitor_removed(ws.id));
    }

    ~DBusWorkspace() {
      if (this._obj_id > 0) {
        if (this.connection.unregister_object(this._obj_id)) {
          this._obj_id = 0;
        }
      }
    }

    public void add_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError {
      var monitor = this.workspace.context.monitor_provider.get_monitor(id);
      if (monitor == null) {
        throw new WorkspaceError.INVALID_MONITOR(_("Invalid monitor %s").printf(id));
      }

      this.workspace.add_monitor(monitor);
    }

    public bool has_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError {
      var monitor = this.workspace.context.monitor_provider.get_monitor(id);
      if (monitor == null) {
        throw new WorkspaceError.INVALID_MONITOR(_("Invalid monitor %s").printf(id));
      }

      return this.workspace.has_monitor(monitor);
    }

    public void remove_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError {
      var monitor = this.workspace.context.monitor_provider.get_monitor(id);
      if (monitor == null) {
        throw new WorkspaceError.INVALID_MONITOR(_("Invalid monitor %s").printf(id));
      }

      this.workspace.remove_monitor(monitor);
    }

    private bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this._is_init) {
        return true;
      }
      this._is_init = true;

      this._obj_id = this.connection.register_object("/com/expidus/genesis/workspace/%llu".printf(this.workspace.id), (IWorkspaceDBus)this);
      return true;
    }
  }
}
