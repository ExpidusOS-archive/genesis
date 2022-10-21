namespace GenesisShell {
  public interface IMonitorProvider : GLib.Object {
    public abstract Context context { get; construct; }

    public virtual Monitor? create_virtual_monitor() {
      return null;
    }

    public abstract unowned Monitor? get_monitor(string id);
    public abstract GLib.List<string> get_monitor_ids();

    public virtual unowned Monitor? get_primary_monitor() {
      foreach (var id in this.get_monitor_ids()) {
        unowned var monitor = this.get_monitor(id);
        if (monitor == null) continue;
        if (monitor.is_primary) return monitor;
      }
      return null;
    }

    public signal void added(Monitor monitor);
    public signal void removed(Monitor monitor);
  }

  [DBus(name = "com.expidus.genesis.MonitorOrientation")]
  public enum MonitorOrientation {
    /**
     * Rotation of 0 degrees
     */
    NORMAL = 0,

    /**
     * Rotation of 90 degrees
     */
    CLOCKWISE,

    /**
     * Rotation of -90 degrees
     */
    COUNTER_CLOCKWISE,

    /**
     * Rotation of 180 degrees
     */
    FLIPPED;

    public static bool try_parse_name(string name, out MonitorOrientation result = null) {
      var enumc = (GLib.EnumClass)(typeof (MonitorOrientation).class_ref());
      unowned var eval = enumc.get_value_by_name(name);

      if (eval == null) {
        result = MonitorOrientation.NORMAL;
        return false;
      }

      result = (MonitorOrientation)eval.value;
      return true;
    }

    public static bool try_parse_nick(string name, out MonitorOrientation result = null) {
      var enumc = (GLib.EnumClass)(typeof (MonitorOrientation).class_ref());
      unowned var eval = enumc.get_value_by_nick(name);
      return_val_if_fail(eval != null, false);

      if (eval == null) {
        result = MonitorOrientation.NORMAL;
        return false;
      }

      result = (MonitorOrientation)eval.value;
      return true;
    }

    public string to_nick() {
      var enumc = (GLib.EnumClass)(typeof (MonitorOrientation).class_ref());
      var eval  = enumc.get_value(this);
      return_val_if_fail(eval != null, null);
      return eval.value_nick;
    }
  }

  [DBus(name = "com.expidus.genesis.MonitorError")]
  public errordomain MonitorError {
    INVALID_WORKSPACE
  }

  [DBus(name = "com.expidus.genesis.MonitorMode")]
  public struct MonitorMode {
    public int width;
    public int height;
    public int depth;
    public double rate;

    public const string VARIANT_FORMAT = "(nnnd)";
    public const string STRING_FORMAT = N_("%dx%d (%d) %f Hz");

    public MonitorMode(int width, int height, int depth, double rate) {
      this.width = width;
      this.height = height;
      this.depth = depth;
      this.rate = rate;
    }

    public MonitorMode.from_variant(GLib.Variant variant) {
      assert_cmpstr(variant.get_type().dup_string(), GLib.CompareOperator.EQ, VARIANT_FORMAT);
      variant.get(VARIANT_FORMAT, out this.width, out this.height, out this.depth, out this.rate);
    }

    public MonitorMode.from_string(string str) {
      str.scanf(STRING_FORMAT, out this.width, out this.height, out this.depth, out this.rate);
    }

    public GLib.Variant to_variant() {
      return new GLib.Variant(VARIANT_FORMAT, this.width, this.height, this.depth, out this.rate);
    }

    public string to_string() {
      return STRING_FORMAT.printf(this.width, this.height, this.depth, this.rate);
    }
  }

#if HAS_DBUS
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
#endif

  public abstract class Monitor : GLib.Object, GLib.Initable {
    private bool _is_init;
    private GLib.List<Workspace> _workspaces;
    private WindowManager? _window_manger;

    public const string VARIANT_FORMAT = "a{sv}";
    
#if HAS_DBUS
    internal DBusMonitor dbus { get; }
#endif

    /**
     * The context of the shell the monitor is a part of
     */
    public Context context {
      get {
        return this.provider.context;
      }
    }

    public WindowManager? window_manager {
      get {
        return this._window_manger;
      }
      set {
        if (this._window_manger != null) this._window_manger.remove_monitor(this);

        this._window_manger = value;
        this._window_manger.add_monitor(this);
      }
    }

    /**
     * The workspaces attached to this monitor
     */
    public GLib.List<weak Workspace> workspaces {
      owned get {
        return this._workspaces.copy();
      }
    }

    /**
     * The monitor provider which provisioned the monitor.
     */
    public IMonitorProvider provider { get; construct; }

    /**
     * The ID of the monitor
     */
    public abstract string id { get; }

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
    public abstract GLib.Bytes? edid { get; }

    public string? wallpaper { get; set; }

    /**
     * The scale to multiple the DPI by
     */
    public double scale { get; set; default = 1.0; }

    /**
     * The monitor's dots per inch (also known as pixels per inch).
     *
     * This is used to scale UI elements on the monitor.
     *
     * If physical_width or physical_height is less than 1 then it defaults to 96 DPI
     * multiple by the scale.
     */
    public double dpi {
      get {
        if (this.physical_width < 1 || this.physical_height < 1) return 96.0 * this.scale;

        var diag_inch = GLib.Math.sqrt(GLib.Math.pow(this.physical_width, 2) + GLib.Math.pow(this.physical_height, 2)) * 0.039370;
        var diag_px = GLib.Math.sqrt(GLib.Math.pow(this.mode.width, 2) + GLib.Math.pow(this.mode.height, 2));
        return (diag_px / diag_inch) * this.scale;
      }
    }

    /**
     * The rotation (or orientation) of the monitor.
     */
    public abstract MonitorOrientation orientation { get; set; }

    /**
     * The monitor ID to mirror
     *
     * This is the ID of the monitor to mirror from, set to null
     * will stop mirroring.
     */
    public abstract string? mirroring { get; set; }

    /**
     * Whether or not the monitor is a physical or virtual one.
     */
    public abstract bool is_physical { get; }

    /**
     * Wether or not the monitor is the primary monitor.
     */
    public abstract bool is_primary { get; set; }

    construct {
      if (this.wallpaper == null) this.wallpaper = this.get_default_wallpaper();

      this.notify.connect(() => this.save_settings());
    }

    public string get_default_wallpaper() {
      var device = this.context.devident.get_default();
      if (device != null) {
        switch (device.kind) {
          case Devident.DeviceKind.PHONE:
            return DATADIR + "/backgrounds/genesis-shell/mobile/default.jpg";
          default:
            if (this.mode.width < this.mode.height) return DATADIR + "/backgrounds/genesis-shell/mobile/default.jpg";
            return DATADIR + "/backgrounds/genesis-shell/desktop/default.jpg";
        }
      }
      return DATADIR + "/backgrounds/genesis-shell/desktop/default.jpg";
    }

    /**
     * List all monitor modes
     *
     * This returns a list of every monitor mode which were found
     * to be supported by the monitor.
     */
    public abstract GLib.List<MonitorMode?> list_modes();

    /**
     * Check if the provided mode is available for the monitor.
     *
     * This performs a check against what the monitor supports to
     * determine whether or not the monitor can run at that mode.
     */
    public virtual bool is_mode_available(MonitorMode mode) {
      var modes = this.list_modes();
      foreach (var avail_mode in modes) {
        if (avail_mode.width == mode.width
          && avail_mode.height == mode.height
          && avail_mode.depth == mode.depth
          && avail_mode.rate == mode.rate) return true;
      }
      return false;
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
        this.workspace_removed(workspace);
      }
    }

    public bool has_workspace(Workspace workspace) {
      unowned var item = this._workspaces.find_custom(workspace, (a, b) => (int)(a.id > b.id) - (int)(a.id < b.id));
      return item != null;
    }

    public GLib.Variant to_variant() {
      var builder = new GLib.VariantBuilder(new GLib.VariantType(VARIANT_FORMAT));
      builder.add("{sv}", "id", new GLib.Variant.string(this.id));
      builder.add("{sv}", "mode", this.mode.to_variant());
      builder.add("{sv}", "orientation", new GLib.Variant.int16(this.orientation));
      builder.add("{sv}", "is-primary", new GLib.Variant.boolean(this.is_primary));
      builder.add("{sv}", "scale", new GLib.Variant.double(this.scale));
      builder.add("{sv}", "x", new GLib.Variant.int32(this.x));
      builder.add("{sv}", "y", new GLib.Variant.int32(this.y));
      builder.add("{sv}", "wallpaper", new GLib.Variant.string(this.wallpaper == null ? this.get_default_wallpaper() : this.wallpaper));

      if (this.mirroring != null) builder.add("{sv}", "mirroring", new GLib.Variant.string(this.mirroring));
      return builder.end();
    }

    public signal void workspace_added(Workspace workspace);
    public signal void workspace_removed(Workspace workspace);

    public virtual bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

#if HAS_DBUS
      this._dbus = new DBusMonitor(this, this.context.dbus.connection, cancellable);
#endif
      return true;
    }

    internal void load_settings() {
      var monitors = this.context.settings.get_value("monitors");
      assert(monitors.is_of_type(new VariantType(VARIANT_FORMAT)));

      var value = monitors.lookup_value(this.id, null);
      if (value == null) {
        this.save_settings();
        return;
      }

      GLib.debug(N_("Loading monitor \"%s\": %s (%d)"), this.id, value.print(true), value.n_children());
      assert_cmpstr(value.lookup_value("id", GLib.VariantType.STRING).get_string(), GLib.CompareOperator.EQ, this.id);

      this.mode = MonitorMode.from_variant(value.lookup_value("mode", new GLib.VariantType(MonitorMode.VARIANT_FORMAT)));
      this.orientation = (MonitorOrientation)value.lookup_value("orientation", GLib.VariantType.INT16).get_int16();
      this.is_primary = value.lookup_value("is-primary", GLib.VariantType.BOOLEAN).get_boolean();
      this.scale = value.lookup_value("scale", GLib.VariantType.DOUBLE).get_double();
      this.x = value.lookup_value("x", GLib.VariantType.INT32).get_int32();
      this.y = value.lookup_value("y", GLib.VariantType.INT32).get_int32();

      var child = value.lookup_value("mirroring", GLib.VariantType.STRING);
      if (child != null) this.mirroring = child.get_string();

      child = value.lookup_value("wallpaper", GLib.VariantType.STRING);
      if (child != null) this.wallpaper = child.get_string();
    }

    internal void save_settings() {
      var builder = new GLib.VariantBuilder(new GLib.VariantType(VARIANT_FORMAT));

      var monitors = this.context.settings.get_value("monitors");
      assert(monitors.is_of_type(new VariantType(VARIANT_FORMAT)));

      foreach (var monitor in monitors) {
        var id = monitor.get_child_value(0).get_string();
        if (id == this.id) continue;

        builder.add("{sv}", id, monitor.get_child_value(1).get_child_value(0));
      }

      builder.add("{sv}", this.id, this.to_variant());

      var value = builder.end();
      GLib.debug(N_("Setting monitors to \"%s\""), value.print(true));
      this.context.settings.set_value("monitors", value);
    }
  }

#if HAS_DBUS
  private sealed class DBusMonitor : GLib.Object, IMonitorDBus, GLib.Initable {
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
        if (this.monitor.edid == null) return null;
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

    public string? mirroring {
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

    internal DBusMonitor(Monitor monitor, GLib.DBusConnection connection, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(monitor: monitor, connection: connection);
      this.init(cancellable);
    }

    internal async DBusMonitor.make_async_connection(Monitor monitor, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(monitor: monitor, connection: yield GLib.Bus.get(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    internal DBusMonitor.make_sync_connection(Monitor monitor, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(monitor: monitor, connection: GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    construct {
      this.monitor.workspace_added.connect((ws) => this.workspace_added(ws.id));
      this.monitor.workspace_removed.connect((ws) => this.workspace_removed(ws.id));
    }

    ~DBusMonitor() {
      if (this._obj_id > 0) {
        if (this.connection.unregister_object(this._obj_id)) this._obj_id = 0;
      }
    }

    private bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

      this._obj_id = this.connection.register_object("/com/expidus/genesis/monitor/%s".printf(this.monitor.id.replace(" ", "").replace(",", "")), (IMonitorDBus)this);
      return true;
    }

    public MonitorMode[] list_modes() throws GLib.DBusError, GLib.IOError {
      var list = this.monitor.list_modes();
      MonitorMode[] arr = {};
      foreach (var mode in list) arr += mode;
      return arr;
    }

    public bool is_mode_available(MonitorMode mode) throws GLib.DBusError, GLib.IOError {
      return this.monitor.is_mode_available(mode);
    }

    public void add_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError {
      var workspace = this.monitor.context.workspace_provider.get_workspace(id);
      if (workspace == null) throw new MonitorError.INVALID_WORKSPACE(N_("Invalid workspace %llu").printf(id));

      this.monitor.add_workspace(workspace);
    }

    public void remove_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError {
      var workspace = this.monitor.context.workspace_provider.get_workspace(id);
      if (workspace == null) throw new MonitorError.INVALID_WORKSPACE(N_("Invalid workspace %llu").printf(id));

      this.monitor.remove_workspace(workspace);
    }

    public bool has_workspace(WorkspaceID id) throws GLib.DBusError, GLib.IOError, MonitorError {
      var workspace = this.monitor.context.workspace_provider.get_workspace(id);
      if (workspace == null) throw new MonitorError.INVALID_WORKSPACE(N_("Invalid workspace %llu").printf(id));

      return this.monitor.has_workspace(workspace);
    }

    public GLib.Variant to_variant() throws GLib.DBusError, GLib.IOError {
      return this.monitor.to_variant();
    }
  }
#endif
}
