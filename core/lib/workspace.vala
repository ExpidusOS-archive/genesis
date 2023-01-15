namespace GenesisShell {
  private static WorkspaceID next_workspace_id = 1;

  public interface IWorkspaceProvider : GLib.Object {
    public abstract Context context { get; construct; }

    public abstract Workspace ? create_workspace(string name);

    public abstract GLib.List <WorkspaceID ?> get_workspace_ids();
    public abstract unowned Workspace ? get_workspace(WorkspaceID id);
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

  [DBus(name = "com.expidus.genesis.WorkspaceError")]
  public errordomain WorkspaceError {
    INVALID_MONITOR
  }

  public abstract class Workspace : GLib.Object, GLib.Initable {
    private bool _is_init;
    private WindowManager ?_window_manger;

#if HAS_DBUS
    internal DBusWorkspace dbus { get; }
#endif

    public Context context {
      get {
        return this.provider.context;
      }
    }

    public IWorkspaceProvider provider { get; construct; }
    public string name { get; construct; }
    public WorkspaceID id { get; }

    public WindowManager ?window_manager {
      get {
        return this._window_manger;
      }
      set {
        if (this._window_manger != null) {
          this._window_manger.remove_workspace(this);
        }

        this._window_manger = value;
        this._window_manger.add_workspace(this);
      }
    }

    public GLib.List <weak Monitor> monitors {
      owned get {
        var list = new GLib.List <weak Monitor>();
        foreach (var id in this.context.monitor_provider.get_monitor_ids()) {
          unowned var monitor = this.context.monitor_provider.get_monitor(id);
          if (monitor == null) {
            continue;
          }
          if (monitor.has_workspace(this)) {
            list.append(monitor);
          }
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

    public virtual bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this._is_init) {
        return true;
      }
      this._is_init = true;

#if HAS_DBUS
      this._dbus = new DBusWorkspace(this, this.context.dbus.connection, cancellable);
#endif
      return true;
    }

    public signal void monitor_added(Monitor monitor);
    public signal void monitor_removed(Monitor monitor);
  }
}
