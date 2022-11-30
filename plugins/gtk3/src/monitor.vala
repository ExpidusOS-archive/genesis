namespace GenesisShellGtk3 {
  public class Monitor : GenesisShell.Monitor {
    private string _id;
    private GenesisShell.MonitorMode _mode;
    public Gdk.Monitor gdk_monitor { get; construct; }

    public DesktopWindow? desktop { get; }
    public PanelWindow ?panel { get; }
    public DashboardWindow ?dash { get; }
    public AppsWindow ?apps { get; }
    public LockWindow ?lock { get; }

    public PanelWidget? panel_widget {
      get {
        if (this._panel != null) return this._panel.widget;
        if (this._desktop != null) {
          if (this._desktop.widget != null) {
            return this._desktop.widget.panel;
          }
        }
        return null;
      }
    }

    public DashboardWidget? dash_widget {
      get {
        if (this._dash != null) return this._dash.widget;
        if (this._desktop != null) {
          if (this._desktop.widget != null) {
            return this._desktop.widget.dash;
          }
        }
        return null;
      }
    }

    public AppsWidget? apps_widget {
      get {
        if (this._apps != null) return this._apps.widget;
        if (this._desktop != null) {
          if (this._desktop.widget != null) {
            return this._desktop.widget.apps;
          }
        }
        return null;
      }
    }

    public LockWidget? lock_widget {
      get {
        if (this._lock != null) return this._lock.widget;
        if (this._lock != null) {
          if (this._lock.widget != null) {
            return this._desktop.widget.lock;
          }
        }
        return null;
      }
    }

    public override GLib.Bytes ?edid {
      get {
        return null;
      }
    }

    public override string id {
      get {
        if (this._id == null) {
          this._id = Monitor.name_for(this.gdk_monitor);
        }
        return this._id;
      }
    }

    public override bool is_physical {
      get {
        return true;
      }
    }

    public override bool is_primary {
      get {
        return this.gdk_monitor.is_primary();
      }
      set {
        GLib.warning(_("Unuspported feature on monitor: set is-primary"));
      }
    }

    public override string ?mirroring {
      get {
        return null;
      }
      set {
        GLib.warning(_("Unuspported feature on monitor: set mirroring"));
      }
    }

    public override GenesisShell.MonitorMode mode {
      get {
        var screen = this.gdk_monitor.get_display().get_default_screen();
        var visual = screen.get_rgba_visual() == null ?screen.get_system_visual() : screen.get_rgba_visual();

        this._mode = GenesisShell.MonitorMode(
          this.gdk_monitor.geometry.width,
          this.gdk_monitor.geometry.height,
          visual.get_depth(),
          this.gdk_monitor.refresh_rate / 1000
          );
        return this._mode;
      }
      set {
        GLib.warning(_("Unuspported feature on monitor: set mode"));
      }
    }

    public override GenesisShell.MonitorOrientation orientation {
      get {
        return GenesisShell.MonitorOrientation.NORMAL;
      }
      set {
        GLib.warning(_("Unuspported feature on monitor: set orientation"));
      }
    }

    public override int physical_width {
      get {
        return this.gdk_monitor.width_mm;
      }
    }

    public override int physical_height {
      get {
        return this.gdk_monitor.height_mm;
      }
    }

    public override int x {
      get {
        return this.gdk_monitor.geometry.x;
      }
      set {
        GLib.warning(_("Unuspported feature on monitor: set x"));
      }
    }

    public override int y {
      get {
        return this.gdk_monitor.geometry.y;
      }
      set {
        GLib.warning(_("Unuspported feature on monitor: set y"));
      }
    }

    internal Monitor(GenesisShell.IMonitorProvider provider, Gdk.Monitor monitor, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(provider: provider, gdk_monitor: monitor);
      this.init(cancellable);
    }

    public override bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      base.init(cancellable);

      this._desktop = new DesktopWindow(this);
      if (this.context.mode == GenesisShell.ContextMode.GADGETS) {
        this._panel = new PanelWindow(this);

        this._dash = new DashboardWindow(this);
        this._dash.no_show_all = true;

        this._apps = new AppsWindow(this);
        this._apps.no_show_all = true;

        this._lock = new LockWindow(this);
        this._lock.no_show_all = true;
      }

      if (this.is_primary) {
        Gtk.Settings.get_default().gtk_xft_dpi = (int)this.dpi;
      }
      return true;
    }

    public override GLib.List <GenesisShell.MonitorMode ?> list_modes() {
      var list    = new GLib.List <GenesisShell.MonitorMode ?>();
      var visuals = this.gdk_monitor.get_display().get_default_screen().list_visuals();
      var depths  = new GLib.List <int>();

      foreach (var visual in visuals) {
        if (depths.find(visual.get_depth()) == null) {
          depths.append(visual.get_depth());
        }
      }

      foreach (var depth in depths) {
        list.append(GenesisShell.MonitorMode(
                      this.gdk_monitor.geometry.width,
                      this.gdk_monitor.geometry.height,
                      depth,
                      this.gdk_monitor.refresh_rate / 1000
                      ));
      }
      return list;
    }

    public signal GLib.Value? action(GenesisShell.UIElementKind elem, GenesisShell.UIActionKind action, string[] names, GLib.Value[] values) {
      var value = GLib.Value(GLib.Type.BOOLEAN);
      value.set_boolean(false);

      switch (elem) {
        case GenesisShell.UIElementKind.DASH:
          if (this.dash_widget != null) {
            if (action == GenesisShell.UIActionKind.OPEN) {
              this.dash_widget.show_all();
              value.set_boolean(true);
            } else if (action == GenesisShell.UIActionKind.CLOSE) {
              this.dash_widget.hide();
              value.set_boolean(true);
            } else if (action == GenesisShell.UIActionKind.TOGGLE_OPEN) {
              if (this.dash_widget.visible) this.dash_widget.hide();
              else this.dash_widget.show_all();
              value.set_boolean(true);
            }
          }
          break;
        case GenesisShell.UIElementKind.LOCK:
          if (this.lock_widget != null) {
            if (action == GenesisShell.UIActionKind.OPEN) {
              this.lock_widget.show_all();
              value.set_boolean(true);
            } else if (action == GenesisShell.UIActionKind.CLOSE) {
              this.lock_widget.hide();
              value.set_boolean(true);
            } else if (action == GenesisShell.UIActionKind.TOGGLE_OPEN) {
              if (this.lock_widget.visible) this.lock_widget.hide();
              else this.lock_widget.show_all();
              value.set_boolean(true);
            }
          }
          break;
        default:
          break;
      }
      return value;
    }

    internal static string name_for(Gdk.Monitor monitor) {
      return monitor.get_model();
    }
  }
}
