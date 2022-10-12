namespace GenesisShell {
  public interface IMonitorProvider : GLib.Object {
    public abstract Context context { get; construct; }

    public abstract Monitor? create_virtual_monitor();

    public abstract unowned Monitor? get_monitor(string id);
    public abstract GLib.List<string> get_monitor_ids();

    public unowned Monitor? get_primary_monitor() {
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
    FLIPPED
  }

  [DBus(name = "com.expidus.genesis.MonitorMode")]
  public struct MonitorMode {
    public int width;
    public int height;
    public int depth;
    public double rate;

    public const string VARIANT_FORMAT = "nnnd";
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
  }

  public abstract class Monitor : GLib.Object, GLib.Initable {
    private bool _is_init;
    internal DBusMonitor dbus { get; }

    /**
     * The context of the shell the monitor is a part of
     */
    public Context context {
      get {
        return this.provider.context;
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
    public abstract bool is_mode_available(MonitorMode mode);

    public virtual bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

      this._dbus = new DBusMonitor(this, this.context.dbus.connection, cancellable);
      return true;
    }
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

    ~DBusMonitor() {
      if (this._obj_id > 0) {
        if (this.connection.unregister_object(this._obj_id)) this._obj_id = 0;
      }
    }

    private bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

      this._obj_id = this.connection.register_object("/com/expidus/genesis/monitor/%s".printf(this.monitor.id), (IMonitorDBus)this);
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
  }
}
