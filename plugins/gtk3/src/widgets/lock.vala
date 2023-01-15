namespace GenesisShellGtk3 {
  public sealed class LockWidget : Gtk.Bin, GenesisShell.IUIElement {
    public GenesisShell.UIElementKind kind {
      get {
        return GenesisShell.UIElementKind.LOCK;
      }
    }

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }

    internal LockWidget(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    private int get_width() {
      return this.monitor.mode.width;
    }

    private int get_height() {
      return this.monitor.mode.height;
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_width();
    }

    public override void get_preferred_height(out int min_height, out int nat_height) {
      min_height = nat_height = this.get_height();
    }
  }
}
