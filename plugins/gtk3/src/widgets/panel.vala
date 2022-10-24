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

    public static PanelApplet @new(GLib.Type type, GenesisShell.Monitor monitor, string id) {
      return (PanelApplet)GLib.Object.new(type, "monitor", monitor, "id", id);
    }
  }

  public sealed class PanelWidget : Hdy.HeaderBar {
    private ulong _mode_id;
    private Gtk.Box _left;
    private Gtk.Box _center;
    private Gtk.Box _right;
    private GLib.List<PanelApplet> _applets;
    private GLib.HashTable<string, ulong> _applet_sigs;

    public Gtk.Label clock { get; }

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }

    public GLib.List<unowned PanelApplet> applets {
      owned get {
        return this._applets.copy();
      }
    }

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
      this._applet_sigs = new GLib.HashTable<string, ulong>(GLib.str_hash, GLib.str_equal);

      this._left = new Gtk.Box(Gtk.Orientation.HORIZONTAL, GenesisShell.Math.em(this.monitor.dpi, 0.5));
      this._left.halign = Gtk.Align.START;
      this._left.hexpand = true;

      this._center = new Gtk.Box(Gtk.Orientation.HORIZONTAL, GenesisShell.Math.em(this.monitor.dpi, 0.5));
      this._center.halign = Gtk.Align.CENTER;
      this._center.hexpand = true;

      this._right = new Gtk.Box(Gtk.Orientation.HORIZONTAL, GenesisShell.Math.em(this.monitor.dpi, 0.5));
      this._right.halign = Gtk.Align.END;
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

      var clock = new PanelApplets.Clock(this.monitor, "clock-0");
      clock.side = PanelAppletSide.RIGHT;
      this.add_applet(clock);
    }

    private int get_width() {
      return (int)(this.monitor.mode.width * 0.99);
    }

    private int get_height() {
      return GenesisShell.Math.em(this.monitor.dpi, 0.85);
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

    private Gtk.Box get_side(PanelAppletSide side) {
      switch (side) {
        case PanelAppletSide.LEFT:
          return this._left;
        case PanelAppletSide.CENTER:
          return this._center;
        case PanelAppletSide.RIGHT:
          return this._right;
      }
      return null;
    }

    public bool has_applet(PanelApplet applet) {
      return this.find_applet(applet) != null;
    }

    public void add_applet(PanelApplet applet) {
      if (this.find_applet(applet) == null) {
        this._applets.append(applet);
        this.applet_added(applet);

        var old_side = applet.side;
        this._applet_sigs.set(applet.id, applet.notify["side"].connect(() => {
          this.get_side(old_side).remove(applet);
          this.get_side(applet.side).add(applet);
          old_side = applet.side;
        }));

        this.get_side(applet.side).add(applet);
      }
    }

    public void remove_applet(PanelApplet applet) {
      unowned var elem = this.find_applet(applet);
      if (elem != null) {
        this.applet_removed(elem.data);
        this._applets.remove_link(elem);

        var sig = this._applet_sigs.get(applet.id);
        this._applet_sigs.remove(applet.id);
        applet.disconnect(sig);

        this.get_side(applet.side).remove(applet);
      }
    }

    public signal void applet_added(PanelApplet applet);
    public signal void applet_removed(PanelApplet applet);
  }
}
