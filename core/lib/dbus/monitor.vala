namespace GenesisShell {
  [DBus(name = "com.expidus.genesis.Monitor")]
  public interface IMonitorDBus : GLib.Object {
    /**
     * The ID of the monitor
     */
    public abstract string id { owned get; }

    /**
     * The X position in the monitor coordinate space.
     */
    public abstract int x { get; set; }

    /**
     * The Y position in the monitor coordinate space.
     */
    public abstract int y { get; set; }

    /**
     * The physical width of the monitor in millimeters.
     */
    public abstract int physical_width { get; }

    /**
     * The physical height of the monitor in millimeters.
     */
    public abstract int physical_height { get; }

    /**
     * The display mode of the monitor.
     */
    public abstract MonitorMode mode { get; set; }

    /**
     * The raw EDID (Extended Display Identification Data) of the monitor.
     *
     * This is the raw EDID of the monitor, this can be null if the monitor's
     * EDID could not be found.
     */
    public abstract uint8[]? edid { owned get; }

    /**
     * The scale to multiple the DPI by
     */
    public abstract double scale { get; set; }

    /**
     * The monitor's dots per inch (also known as pixels per inch).
     *
     * This is used to scale UI elements on the monitor.
     *
     * If physical_width or physical_height is less than 1 then it defaults to 96 DPI
     * multiple by the scale.
     */
    public abstract double dpi { get; }

    /**
     * List all monitor modes
     *
     * This returns a list of every monitor mode which were found
     * to be supported by the monitor.
     */
    public abstract MonitorMode[] list_modes() throws GLib.DBusError, GLib.IOError;

    /**
     * Check if the provided mode is available for the monitor.
     *
     * This performs a check against what the monitor supports to
     * determine whether or not the monitor can run at that mode.
     */
    public abstract bool is_mode_available(MonitorMode mode) throws GLib.DBusError, GLib.IOError;

    public abstract void add_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError;
    public abstract void remove_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError;
    public abstract bool has_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError;

    public abstract GLib.Variant to_variant() throws GLib.DBusError, GLib.IOError;

    public signal void workspace_added(WorkspaceID id);
    public signal void workspace_removed(WorkspaceID id);
  }

  internal sealed class DBusMonitor : GLib.Object, IMonitorDBus, GLib.Initable {
    private bool _is_init = false;
    private uint _obj_id;

    public GLib.DBusConnection connection { get; construct; }
    public Monitor monitor { get; construct; }

    public double dpi {
      get {
        return this.monitor.dpi;
      }
    }

    public uint8[]? edid {
      owned get {
        if (this.monitor.edid == null) {
          return null;
        }
        return this.monitor.edid.get_data();
      }
    }

    public string id {
      owned get {
        return this.monitor.id;
      }
    }

    public bool is_physical {
      get {
        return this.monitor.is_physical;
      }
    }

    public bool is_primary {
      get {
        return this.monitor.is_primary;
      }
    }

    public string ?mirroring {
      get {
        return this.monitor.mirroring;
      }
      set {
        this.monitor.mirroring = value;
      }
    }

    public MonitorMode mode {
      get {
        return this.monitor.mode;
      }
      set {
        this.monitor.mode = value;
      }
    }

    public MonitorOrientation orientation {
      get {
        return this.monitor.orientation;
      }
      set {
        this.monitor.orientation = value;
      }
    }

    public int physical_width {
      get {
        return this.monitor.physical_width;
      }
    }

    public int physical_height {
      get {
        return this.monitor.physical_height;
      }
    }

    public double scale {
      get {
        return this.monitor.scale;
      }
      set {
        this.monitor.scale = value;
      }
    }

    public int x {
      get {
        return this.monitor.x;
      }
      set {
        this.monitor.x = value;
      }
    }

    public int y {
      get {
        return this.monitor.y;
      }
      set {
        this.monitor.y = value;
      }
    }

    internal DBusMonitor(Monitor monitor, GLib.DBusConnection connection, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(monitor: monitor, connection: connection);
      this.init(cancellable);
    }

    internal async DBusMonitor.make_async_connection(Monitor monitor, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(monitor: monitor, connection: yield GLib.Bus.get(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    internal DBusMonitor.make_sync_connection(Monitor monitor, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(monitor: monitor, connection: GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    construct {
      this.monitor.workspace_added.connect((ws) => this.workspace_added(ws.id));
      this.monitor.workspace_removed.connect((ws) => this.workspace_removed(ws.id));
    }

    ~DBusMonitor() {
      if (this._obj_id > 0) {
        if (this.connection.unregister_object(this._obj_id)) {
          this._obj_id = 0;
        }
      }
    }

    private bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this._is_init) {
        return true;
      }
      this._is_init = true;

      this._obj_id = this.connection.register_object("/com/expidus/genesis/monitor/%s".printf(this.monitor.id.replace(" ", "").replace(",", "")), (IMonitorDBus)this);
      return true;
    }

    public MonitorMode[] list_modes() throws GLib.DBusError, GLib.IOError {
      var           list = this.monitor.list_modes();
      MonitorMode[] arr  = {};
      foreach (var mode in list) {
        arr += mode;
      }
      return arr;
    }

    public bool is_mode_available(MonitorMode mode) throws GLib.DBusError, GLib.IOError {
      return this.monitor.is_mode_available(mode);
    }

    public void add_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError {
      var workspace = this.monitor.context.workspace_provider.get_workspace(id);
      if (workspace == null) {
        throw new MonitorError.INVALID_WORKSPACE(_("Invalid workspace %llu").printf(id));
      }

      this.monitor.add_workspace(workspace);
    }

    public void remove_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError {
      var workspace = this.monitor.context.workspace_provider.get_workspace(id);
      if (workspace == null) {
        throw new MonitorError.INVALID_WORKSPACE(_("Invalid workspace %llu").printf(id));
      }

      this.monitor.remove_workspace(workspace);
    }

    public bool has_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError {
      var workspace = this.monitor.context.workspace_provider.get_workspace(id);
      if (workspace == null) {
        throw new MonitorError.INVALID_WORKSPACE(_("Invalid workspace %llu").printf(id));
      }

      return this.monitor.has_workspace(workspace);
    }

    public GLib.Variant to_variant() throws GLib.DBusError, GLib.IOError {
      return this.monitor.to_variant();
    }
  }
}
