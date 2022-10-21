namespace GenesisShellGtk3 {
  public sealed class PanelWidget : Hdy.HeaderBar {
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

    construct {
      this.halign = Gtk.Align.CENTER;

      this._clock = new Gtk.Label("AAAAA");
      this.add(this.clock);
    }

    private int get_width() {
      return this.monitor.mode.width;
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
  }
}
