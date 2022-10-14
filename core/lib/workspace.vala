namespace GenesisShell {
  private static size_t next_workspace_id = 1;

  public interface IWorkspaceProvider : GLib.Object {
    public abstract Context context { get; construct; }

    public abstract GLib.List<WorkspaceID?> get_workspace_ids();
    public abstract unowned Workspace? get_workspace(WorkspaceID id);
  }

  [CCode(type_signature = "x")]
  public struct WorkspaceID : size_t {
    public bool is_set() {
      return this > 0;
    }

    public static size_t count() {
      return next_workspace_id - 1;
    }

    internal static WorkspaceID next() {
      return next_workspace_id++;
    }
  }

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

  [DBus(name = "com.expidus.genesis.WorkspaceError")]
  public errordomain WorkspaceError {
    INVALID_MONITOR
  }

  public abstract class Workspace : GLib.Object, GLib.Initable {
    private bool _is_init;
    internal DBusWorkspace dbus { get; }

    public Context context {
      get {
        return this.provider.context;
      }
    }

    public IWorkspaceProvider provider { get; construct; }
    public string name { get; construct; }
    public WorkspaceID id { get; }

    public GLib.List<weak Monitor> monitors {
      owned get {
        var list = new GLib.List<weak Monitor>();
        foreach (var id in this.context.monitor_provider.get_monitor_ids()) {
          unowned var monitor = this.context.monitor_provider.get_monitor(id);
          if (monitor == null) continue;
          if (monitor.has_workspace(this)) list.append(monitor);
        }
        return list;
      }
    }

    construct {
      this._id = WorkspaceID.next();
    }

    public void add_monitor(Monitor monitor) {
      if (!this.has_monitor(monitor)) {
        monitor.add_workspace(this);
        this.monitor_added(monitor);
      }
    }

    public bool has_monitor(Monitor monitor) {
      unowned var item = this.monitors.find_custom(monitor, (a, b) => GLib.strcmp(a.id, b.id));
      return item != null;
    }

    public void remove_monitor(Monitor monitor) {
      if (this.has_monitor(monitor)) {
        monitor.remove_workspace(this);
        this.monitor_removed(monitor);
      }
    }

    public virtual bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

      this._dbus = new DBusWorkspace(this, this.context.dbus.connection, cancellable);
      return true;
    }

    public signal void monitor_added(Monitor monitor);
    public signal void monitor_removed(Monitor monitor);
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
        foreach (var monitor in this.workspace.monitors) value += monitor.id;
        return value;
      }
    }

    public WorkspaceID id {
      get {
        return this.workspace.id;
      }
    }

    internal DBusWorkspace(Workspace workspace, GLib.DBusConnection connection, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(workspace: workspace, connection: connection);
      this.init(cancellable);
    }

    internal async DBusWorkspace.make_async_connection(Workspace workspace, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(workspace: workspace, connection: yield GLib.Bus.get(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    internal DBusWorkspace.make_sync_connection(Workspace workspace, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(workspace: workspace, connection: GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    construct {
      this.workspace.monitor_added.connect((ws) => this.monitor_added(ws.id));
      this.workspace.monitor_removed.connect((ws) => this.monitor_removed(ws.id));
    }

    ~DBusWorkspace() {
      if (this._obj_id > 0) {
        if (this.connection.unregister_object(this._obj_id)) this._obj_id = 0;
      }
    }

    public void add_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError {
      var monitor = this.workspace.context.monitor_provider.get_monitor(id);
      if (monitor == null) throw new WorkspaceError.INVALID_MONITOR(N_("Invalid monitor %s").printf(id));

      this.workspace.add_monitor(monitor);
    }

    public bool has_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError {
      var monitor = this.workspace.context.monitor_provider.get_monitor(id);
      if (monitor == null) throw new WorkspaceError.INVALID_MONITOR(N_("Invalid monitor %s").printf(id));

      return this.workspace.has_monitor(monitor);
    }

    public void remove_monitor(string id) throws GLib.DBusError, GLib.IOError, WorkspaceError {
      var monitor = this.workspace.context.monitor_provider.get_monitor(id);
      if (monitor == null) throw new WorkspaceError.INVALID_MONITOR(N_("Invalid monitor %s").printf(id));

      this.workspace.remove_monitor(monitor);
    }

    private bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

      this._obj_id = this.connection.register_object("/com/expidus/genesis/workspace/%llu".printf(this.workspace.id), (IWorkspaceDBus)this);
      return true;
    }
  }
}
