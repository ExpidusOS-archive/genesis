namespace GenesisShell {
  private static WindowID next_window_id = 1;

  [CCode(type_signature = "x")]
  public struct WindowID : size_t {
    public bool is_set() {
      return this > 0;
    }

    public static size_t count() {
      return next_window_id - 1;
    }

    internal static WindowID next() {
      return next_window_id++;
    }
  }

  [DBus(name = "com.expidus.genesis.WindowShellLayer")]
  public enum WindowShellLayer {
    BACKGROUND = 0,
    BOTTOM,
    TOP,
    OVERLAY;

    public static bool try_parse_name(string name, out WindowShellLayer result = null) {
      var enumc        = (GLib.EnumClass)(typeof(WindowShellLayer).class_ref());
      unowned var eval = enumc.get_value_by_name(name);

      if (eval == null) {
        result = WindowShellLayer.BACKGROUND;
        return false;
      }

      result = (WindowShellLayer)eval.value;
      return true;
    }

    public static bool try_parse_nick(string name, out WindowShellLayer result = null) {
      var enumc        = (GLib.EnumClass)(typeof(WindowShellLayer).class_ref());
      unowned var eval = enumc.get_value_by_nick(name);
      return_val_if_fail(eval != null, false);

      if (eval == null) {
        result = WindowShellLayer.BACKGROUND;
        return false;
      }

      result = (WindowShellLayer)eval.value;
      return true;
    }

    public string to_nick() {
      var enumc = (GLib.EnumClass)(typeof(WindowShellLayer).class_ref());
      var eval  = enumc.get_value(this);
      return_val_if_fail(eval != null, null);
      return eval.value_nick;
    }
  }

  public interface IWindowProvider : GLib.Object {
    public abstract Context context { get; construct; }

    public abstract unowned Window ? get_window(WindowID id);

    public abstract GLib.List <WindowID ?> get_window_ids();
  }

#if HAS_DBUS
  [DBus(name = "com.expidus.genesis.Window")]
  public interface IWindowDBus : GLib.Object {
    public abstract WindowID id { get; }

    public abstract string monitor { owned get; set; }
    public abstract WorkspaceID workspace { get; set; }
    public abstract Rectangle geometry { get; set; }
  }

  [DBus(name = "com.expidus.genesis.LayerWindow")]
  public interface ILayerWindowDBus : GLib.Object {
    public abstract Box margins { get; set; }
    public abstract WindowShellLayer layer { get; set; }
    public abstract bool allow_keyboard { get; set; }
  }
#endif

  public abstract class Window : GLib.Object, GLib.Initable {
    private bool _is_init;
    private WindowManager ?_window_manger;

#if HAS_DBUS
    internal DBusWindow dbus { get; }
#endif

    public Context context {
      get {
        return this.provider.context;
      }
    }

    public IWindowProvider provider { get; construct; }
    public WindowID id { get; }

    public abstract Monitor monitor { get; set; }
    public abstract Workspace workspace { get; set; }
    public abstract Rectangle geometry { get; set; }

    public WindowManager ?window_manager {
      get {
        return this._window_manger;
      }
      set {
        if (this._window_manger != null) {
          this._window_manger.unmanage(this);
        }

        this._window_manger = value;
        this._window_manger.manage(this);
      }
    }

    construct {
      this._id = WindowID.next();
    }

    public virtual bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this._is_init) {
        return true;
      }
      this._is_init = true;

#if HAS_DBUS
      this._dbus = new DBusWindow(this, this.context.dbus.connection, cancellable);
#endif
      return true;
    }
  }

  public abstract class LayerWindow : Window {
    private bool _is_init;

#if HAS_DBUS
    internal DBusLayerWindow dbus_layer { get; }
#endif

    public abstract Box margins { get; set; }
    public abstract WindowShellLayer layer { get; set; }
    public abstract bool allow_keyboard { get; set; }

    public override bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      base.init(cancellable);

      if (this._is_init) {
        return true;
      }
      this._is_init = true;

#if HAS_DBUS
      this._dbus_layer = new DBusLayerWindow(this, this.context.dbus.connection, cancellable);
#endif
      return true;
    }
  }

#if HAS_DBUS
  private sealed class DBusWindow : GLib.Object, IWindowDBus, GLib.Initable {
    private bool _is_init = false;
    private uint _obj_id;

    public GLib.DBusConnection connection { get; construct; }
    public Window window { get; construct; }

    public WindowID id {
      get {
        return this.window.id;
      }
    }

    public string monitor {
      owned get {
        return this.window.monitor.id;
      }
      set {
        unowned var monitor = this.window.context.monitor_provider.get_monitor(value);
        if (monitor != null) {
          this.window.monitor = monitor;
        }
      }
    }

    public WorkspaceID workspace {
      get {
        return this.window.workspace.id;
      }
      set {
        unowned var workspace = this.window.context.workspace_provider.get_workspace(value);
        if (workspace != null) {
          this.window.workspace = workspace;
        }
      }
    }

    public Rectangle geometry {
      get {
        return this.window.geometry;
      }
      set {
        this.window.geometry = value;
      }
    }

    internal DBusWindow(Window window, GLib.DBusConnection connection, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(window: window, connection: connection);
      this.init(cancellable);
    }

    internal async DBusWindow.make_async_connection(Window window, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(window: window, connection: yield GLib.Bus.get(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    internal DBusWindow.make_sync_connection(Window window, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(window: window, connection: GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    ~DBusWindow() {
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

      this._obj_id = this.connection.register_object("/com/expidus/genesis/window/%llu".printf(this.window.id), (IWindowDBus)this);
      return true;
    }
  }

  internal sealed class DBusLayerWindow : GLib.Object, ILayerWindowDBus, GLib.Initable {
    private bool _is_init = false;
    private uint _obj_id;

    public GLib.DBusConnection connection { get; construct; }
    public LayerWindow window { get; construct; }

    public Box margins {
      get {
        return this.window.margins;
      }
      set {
        this.window.margins = value;
      }
    }

    public WindowShellLayer layer {
      get {
        return this.window.layer;
      }
      set {
        this.window.layer = value;
      }
    }

    public bool allow_keyboard {
      get {
        return this.window.allow_keyboard;
      }
      set {
        this.window.allow_keyboard = value;
      }
    }

    internal DBusLayerWindow(LayerWindow window, GLib.DBusConnection connection, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(window: window, connection: connection);
      this.init(cancellable);
    }

    internal async DBusLayerWindow.make_async_connection(LayerWindow window, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(window: window, connection: yield GLib.Bus.get(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    internal DBusLayerWindow.make_sync_connection(LayerWindow window, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(window: window, connection: GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    ~DBusLayerWindow() {
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

      this._obj_id = this.connection.register_object("/com/expidus/genesis/window/%llu".printf(this.window.id), (ILayerWindowDBus)this);
      return true;
    }
  }
#endif
}
