namespace GenesisShellGtk3 {
  public class Monitor : GenesisShell.Monitor {
    private string _id;
    private GenesisShell.MonitorMode _mode;
    public Gdk.Monitor gdk_monitor { get; construct; }
    public DesktopWindow desktop { get; }
    public PanelWindow? panel { get; }

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
      if (this.context.mode == GenesisShell.ContextMode.GADGETS) this._panel = new PanelWindow(this);

      if (this.is_primary) Gtk.Settings.get_default().gtk_xft_dpi = (int)this.dpi;
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

    internal static string name_for(Gdk.Monitor monitor) {
      return monitor.get_model();
    }
  }
}
