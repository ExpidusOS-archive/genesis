namespace GenesisShellGtk3 {
  public class AppsWidget : Gtk.Bin, GenesisShell.IUIElement {
    public const double UNIT_SIZE = 700.0;
    public const double ACTION_BUTTON_UNIT_SIZE = 80.0;
    public const double ACTION_BUTTON_ICON_UNIT_SIZE = 50.0;

    public Gtk.Box content { get; }

    public GenesisShell.UIElementKind kind {
      get {
        return GenesisShell.UIElementKind.APPS;
      }
    }

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }

    internal AppsWidget(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    construct {
      var spacing = GenesisShell.Math.scale(this.monitor.dpi, 10.0);
      var margin = GenesisShell.Math.scale(this.monitor.dpi, 10.0);

      this._content = new Gtk.Box(Gtk.Orientation.VERTICAL, spacing);
      this._content.margin_top = margin;
      this._content.margin_bottom = margin;
      this._content.margin_start = margin;
      this._content.margin_end = margin;
      this._content.hexpand = true;
      this._content.vexpand = true;
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
        alloc.x = this.monitor.x - (int)(edge / 2);
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
  }
}
