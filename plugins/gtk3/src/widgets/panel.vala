namespace GenesisShellGtk3 {
  public enum PanelAppletSide {
    LEFT = 0,
    CENTER,
    RIGHT
  }

  public abstract class PanelApplet : Gtk.Bin {
    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }
    public PanelAppletSide side { get; set construct; }
    public string id { get; construct; }
  }

  public sealed class PanelWidget : Hdy.HeaderBar {
    private ulong _mode_id;
    private Gtk.Box _left;
    private Gtk.Box _center;
    private Gtk.Box _right;
    private GLib.List<PanelApplet> _applets;

    public Gtk.Label clock { get; }

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }

    internal PanelWidget(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    ~PanelWidget() {
      if (this._mode_id > 0) {
        this.monitor.disconnect(this._mode_id);
        this._mode_id = 0;
      }
    }

    construct {
      this.get_style_context().add_class("genesis-shell-panel");

      this._applets = new GLib.List<PanelApplet>();

      this._left = new Gtk.Box(Gtk.Orientation.HORIZONTAL, GenesisShell.Math.em(this.monitor.dpi, 0.5));
      this._left.halign = Gtk.Align.START;
      this._left.hexpand = true;

      this._center = new Gtk.Box(Gtk.Orientation.HORIZONTAL, GenesisShell.Math.em(this.monitor.dpi, 0.5));
      this._center.halign = Gtk.Align.START;
      this._center.hexpand = true;

      this._right = new Gtk.Box(Gtk.Orientation.HORIZONTAL, GenesisShell.Math.em(this.monitor.dpi, 0.5));
      this._right.halign = Gtk.Align.START;
      this._right.hexpand = true;

      this._mode_id = this.monitor.notify["scale"].connect(() => this.queue_resize());

      var screen = this.get_display().get_default_screen();
      this.app_paintable = screen.is_composited() && screen.get_rgba_visual() != null;
      if (this.app_paintable) this.set_visual(screen.get_rgba_visual());

      this.halign = Gtk.Align.CENTER;
      this.spacing = GenesisShell.Math.em(this.monitor.dpi, 1.0);

      this.pack_start(this._left);
      this.add(this._center);
      this.pack_end(this._right);

      if (!(this.parent is Gtk.Window)) {
        this.margin_top = this.margin_bottom = 5;
      }
    }

    private int get_width() {
      return this.monitor.mode.width - GenesisShell.Math.em(this.monitor.dpi, 2.0);
    }

    private int get_height() {
      return GenesisShell.Math.em(this.monitor.dpi, 1.7);
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_width();
    }

    public override void get_preferred_height(out int min_height, out int nat_height) {
      min_height = nat_height = this.get_height();
    }

    private static int applet_search_func(PanelApplet a, string id) {
      return GLib.strcmp(a.id, id);
    }

    private unowned GLib.List<PanelApplet> find_applet_element_by_id(string id) {
      // FIXME: why is this invalid: this._applets.search(id, (a, str) => GLib.strcmp(a.id, str));
      return this._applets.search(id, applet_search_func);
    }

    private unowned GLib.List<PanelApplet> find_applet(PanelApplet applet) {
      return this._applets.find_custom(applet, (a, b) => GLib.strcmp(a.id, b.id));
    }

    public bool has_applet(PanelApplet applet) {
      return this.find_applet(applet) != null;
    }

    public void add_applet(PanelApplet applet) {
      if (this.find_applet(applet) == null) {
        this._applets.append(applet);
        // this.applet_added(applet);
      }
    }

    public void remove_applet(PanelApplet applet) {
      unowned var elem = this.find_applet(applet);
      if (elem != null) {
        // this.applet_removed(elem.data);
        this._applets.remove_link(elem);
      }
    }

    // FIXME: GObject wtf warning: parameter 1 of type 'GenesisShellGtk3PanelApplet' for signal "GenesisShellGtk3PanelWidget::applet-added" is not a value type
    /* public signal void applet_added(PanelApplet applet);
    public signal void applet_removed(PanelApplet applet); */
  }
}