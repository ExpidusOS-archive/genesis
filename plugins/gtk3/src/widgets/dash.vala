namespace GenesisShellGtk3 {
  public interface IDashIndicator : Gtk.Widget {
    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public abstract GenesisShell.Monitor monitor { get; construct; }
    public abstract string id { get; construct; }
    public abstract Gtk.Image icon { get; }

    public static new IDashIndicator @new(GLib.Type type, GenesisShell.Monitor monitor, string id) {
      return (IDashIndicator)GLib.Object.new(type, "monitor", monitor, "id", id);
    }
  }

  public abstract class DashIndicator : Gtk.ToggleButton, IDashIndicator {
    public GenesisShell.Monitor monitor { get; construct; }
    public string id { get; construct; }
    public Gtk.Image icon { get; }

    construct {
      this._icon = new Icon.for_monitor("error", this.monitor, 30.0);
      this._icon.halign = Gtk.Align.CENTER;
      this._icon.valign = Gtk.Align.CENTER;
      this.add(this._icon);

      this.halign = Gtk.Align.CENTER;
      this.valign = Gtk.Align.CENTER;
    }

    public static new DashIndicator @new(GLib.Type type, GenesisShell.Monitor monitor, string id) {
      return (DashIndicator)GLib.Object.new(type, "monitor", monitor, "id", id);
    }
  }

  public class DashboardWidget : Gtk.Bin, GenesisShell.IUIElement {
    public const double UNIT_SIZE = 250.0;

    private Gtk.Adjustment _scroll_adjust;
    private Gtk.ScrolledWindow _scroll;
    private Gtk.Viewport _scroll_view;
    private Gtk.Box _indicators_box;
    private GLib.List <IDashIndicator> _indicators;

    public Gtk.Box content { get; }

    public GenesisShell.UIElementKind kind {
      get {
        return GenesisShell.UIElementKind.DESKTOP;
      }
    }

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }

    public GLib.List <unowned IDashIndicator> indicators {
      owned get {
        return this._indicators.copy();
      }
    }

    internal DashboardWidget(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    construct {
      this._scroll_adjust = new Gtk.Adjustment(0, 0, 100.0, 1.0, 10.0, 0.0);
      this._scroll = new Gtk.ScrolledWindow(null, this._scroll_adjust);
      this._scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
      this._scroll.shadow_type = Gtk.ShadowType.NONE;
      this.add(this._scroll);

      this._scroll_view = new Gtk.Viewport(null, this._scroll_adjust);
      this._scroll.add(this._scroll_view);

      var spacing = GenesisShell.Math.scale(this.monitor.dpi, 0.05);
      this._content = new Gtk.Box(Gtk.Orientation.VERTICAL, spacing);
      this._scroll_view.add(this._content);

      this._indicators_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, spacing);
      this._content.add(this._indicators_box);
    }

    private unowned GLib.List <IDashIndicator> find_indicator(IDashIndicator indicator) {
      return this._indicators.find_custom(indicator, (a, b) => GLib.strcmp(a.id, b.id));
    }

    public bool has_indicator(IDashIndicator indicator) {
      return this.find_indicator(indicator) != null;
    }

    public void add_indicator(IDashIndicator indicator) {
      if (this.find_indicator(indicator) == null) {
        this._indicators.append(indicator);
        this._indicators_box.add(indicator);
        this.indicator_added(indicator);
      }
    }

    public void remove_indicator(IDashIndicator indicator) {
      unowned var elem = this.find_indicator(indicator);
      if (elem != null) {
        this.indicator_removed(elem.data);
        this._indicators_box.remove(elem.data);
        this._indicators.remove_link(elem);
      }
    }

    private int get_width() {
      return GenesisShell.Math.scale(this.monitor.dpi, UNIT_SIZE);
    }

    private int get_height() {
      var monitor = this.monitor as Monitor;
      assert(monitor != null);

      int min_height;
      int nat_height;
      monitor.panel_widget.get_preferred_height(out min_height, out nat_height);
      return this.monitor.mode.height - (15 + nat_height);
    }

    public override void size_allocate(Gtk.Allocation alloc) {
      if (this.context.mode == GenesisShell.ContextMode.BIG_PICTURE) {
        var monitor = this.monitor as Monitor;
        assert(monitor != null);

        int min_height;
        int nat_height;
        monitor.panel_widget.get_preferred_height(out min_height, out nat_height);

        var edge = this.monitor.mode.width * 0.01;
        alloc.x = (this.monitor.x + this.monitor.mode.width) - (int)(edge / 2);
        alloc.y = this.monitor.y + min_height + 10;

        alloc.width = this.get_width();
        alloc.height = this.get_height();
      }
      base.size_allocate(alloc);
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_width();
    }

    public override void get_preferred_height(out int min_height, out int nat_height) {
      min_height = nat_height = this.get_height();
    }

    public signal void indicator_added(IDashIndicator indicator);
    public signal void indicator_removed(IDashIndicator indicator);
  }
}
