namespace GenesisShellGtk3 {
  public enum PanelAppletSide {
    LEFT = 0,
    CENTER,
    RIGHT
  }

  public interface IPanelApplet : Gtk.Widget {
    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public abstract GenesisShell.Monitor monitor { get; construct; }
    public abstract PanelAppletSide side { get; set construct; }
    public abstract string id { get; construct; }

    public static new IPanelApplet @new(GLib.Type type, GenesisShell.Monitor monitor, string id) {
      return (IPanelApplet)GLib.Object.new(type, "monitor", monitor, "id", id);
    }
  }

  public abstract class PanelApplet : Gtk.Bin, IPanelApplet {
    public GenesisShell.Monitor monitor { get; construct; }
    public PanelAppletSide side { get; set construct; }
    public string id { get; construct; }

    public static new PanelApplet @new(GLib.Type type, GenesisShell.Monitor monitor, string id) {
      return (PanelApplet)GLib.Object.new(type, "monitor", monitor, "id", id);
    }
  }

  public abstract class PanelAppletButton : Gtk.Button, IPanelApplet {
    public GenesisShell.Monitor monitor { get; construct; }
    public PanelAppletSide side { get; set construct; }
    public string id { get; construct; }

    public static new PanelAppletButton @new(GLib.Type type, GenesisShell.Monitor monitor, string id) {
      return (PanelAppletButton)GLib.Object.new(type, "monitor", monitor, "id", id);
    }
  }

  public sealed class PanelWidget : Hdy.HeaderBar, GenesisShell.IUIElement {
    public const double UNIT_SIZE = 20.0;

    private ulong _mode_id;
    private Gtk.Box _left;
    private Gtk.Box _center;
    private Gtk.Box _right;
    private GLib.List <IPanelApplet> _applets;
    private GLib.HashTable <string, ulong> _applet_sigs;

    public Gtk.Label clock { get; }

    public GenesisShell.UIElementKind kind {
      get {
        return GenesisShell.UIElementKind.PANEL;
      }
    }

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }

    public GLib.List <unowned IPanelApplet> applets {
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

    private async void init_async() {
#if HAS_LIBNM
      try {
        var nets = yield new PanelApplets.Networks(this.monitor, "wifi-0");
        nets.side = PanelAppletSide.RIGHT;
        this.add_applet(nets);
      } catch (GLib.Error e) {
        GLib.warning(_("Networking failed to initialize: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
      }
#endif

#if HAS_UPOWER
      try {
        var power = yield new PanelApplets.Power(this.monitor, "power-0");
        power.side = PanelAppletSide.RIGHT;
        this.add_applet(power);
      } catch (GLib.Error e) {
        GLib.warning(_("Power failed to initialize: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
      }
#endif
    }

    construct {
      var style_ctx = this.get_style_context();
      style_ctx.add_class("genesis-shell-panel");
      style_ctx.add_class("genesis-mode-%s".printf(this.context.mode.to_nick()));
      style_ctx.changed.connect(() => this.update_style());

      this._applets     = new GLib.List <IPanelApplet>();
      this._applet_sigs = new GLib.HashTable <string, ulong>(GLib.str_hash, GLib.str_equal);

      var spacing = GenesisShell.Math.scale(this.monitor.dpi, 0.05);
      this._left         = new Gtk.Box(Gtk.Orientation.HORIZONTAL, spacing);
      this._left.halign  = Gtk.Align.START;
      this._left.hexpand = true;

      this._center         = new Gtk.Box(Gtk.Orientation.HORIZONTAL, spacing);
      this._center.halign  = Gtk.Align.CENTER;
      this._center.hexpand = true;

      this._right         = new Gtk.Box(Gtk.Orientation.HORIZONTAL, spacing);
      this._right.halign  = Gtk.Align.END;
      this._right.hexpand = true;

      this._mode_id = this.monitor.notify["scale"].connect(() => this.queue_resize());

      var screen = this.get_display().get_default_screen();
      this.app_paintable = screen.is_composited() && screen.get_rgba_visual() != null;
      if (this.app_paintable) {
        this.set_visual(screen.get_rgba_visual());
      }

      this.halign  = Gtk.Align.CENTER;
      this.spacing = GenesisShell.Math.scale(this.monitor.dpi, spacing);

      this.pack_start(this._left);
      this.add(this._center);
      this.pack_end(this._right);

      if (!(this.parent is Gtk.Window)) {
        this.margin_top = this.margin_bottom = 5;
      }

      var apps  = new PanelApplets.Apps(this.monitor, "apps-0");
      apps.side = PanelAppletSide.LEFT;
      this.add_applet(apps);
      apps.show_all();

#if HAS_IBUS
      var keyboard = new PanelApplets.Keyboard(this.monitor, "keyboard-0");
      keyboard.side = PanelAppletSide.RIGHT;
      this.add_applet(keyboard);
      keyboard.show_all();
#endif

      this.init_async.begin((obj, ctx) => {
        this.init_async.end(ctx);

        var sound = new PanelApplets.Sound(this.monitor, "sound-0");
        sound.side = PanelAppletSide.RIGHT;
        this.add_applet(sound);
        sound.show_all();

        var clock  = new PanelApplets.Clock(this.monitor, "clock-0");
        clock.side = PanelAppletSide.RIGHT;
        this.add_applet(clock);
        clock.show_all();
      });

      this.update_style();
    }

    private void update_style() {
      if (this.context.mode == GenesisShell.ContextMode.BIG_PICTURE) {
        var style_ctx = this.get_style_context();
        var padding = style_ctx.get_padding(style_ctx.get_state());
        this._left.margin_start = padding.left;
        this._right.margin_end = padding.right;
      }

      this.queue_resize();
    }

    private int get_width() {
      return (int)(this.monitor.mode.width * 0.99);
    }

    private int get_height() {
      var value = GenesisShell.Math.scale(this.monitor.dpi, UNIT_SIZE);
      if (this.context.mode == GenesisShell.ContextMode.BIG_PICTURE) {
        var style_ctx = this.get_style_context();
        var padding = style_ctx.get_padding(style_ctx.get_state());
        value += padding.top + padding.bottom;
      }
      return value;
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_width();
    }

    public override void get_preferred_height(out int min_height, out int nat_height) {
      min_height = nat_height = this.get_height();
    }

    private static int applet_search_func(IPanelApplet a, string id) {
      return GLib.strcmp(a.id, id);
    }

    private unowned GLib.List <IPanelApplet> find_applet_element_by_id(string id) {
      // FIXME: why is this invalid: this._applets.search(id, (a, str) => GLib.strcmp(a.id, str));
      return this._applets.search(id, applet_search_func);
    }

    private unowned GLib.List <IPanelApplet> find_applet(IPanelApplet applet) {
      return this._applets.find_custom(applet, (a, b) => GLib.strcmp(a.id, b.id));
    }

    private Gtk.Box ?get_side(PanelAppletSide side) {
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

    public bool has_applet(IPanelApplet applet) {
      return this.find_applet(applet) != null;
    }

    public void add_applet(IPanelApplet applet) {
      if (this.find_applet(applet) == null) {
        this._applets.append(applet);
        this.applet_added(applet);

        var old_side = applet.side;
        this._applet_sigs.set(applet.id, applet.notify["side"].connect(() => {
          this.get_side(old_side).remove(applet);
          this.get_side(applet.side).pack_end(applet);
          old_side = applet.side;
        }));

        this.get_side(applet.side).add(applet);
      }
    }

    public void remove_applet(IPanelApplet applet) {
      unowned var elem = this.find_applet(applet);
      if (elem != null) {
        this.applet_removed(elem.data);
        this._applets.remove_link(elem);

        var sig = this._applet_sigs.get(applet.id);
        this._applet_sigs.remove(applet.id);
        applet.disconnect(sig);

        this.get_side(applet.side).pack_end(applet);
      }
    }

    public signal void applet_added(IPanelApplet applet);
    public signal void applet_removed(IPanelApplet applet);
  }
}
