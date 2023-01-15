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
}
