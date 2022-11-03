namespace GenesisShellGtk3 {
  public class Button : Gtk.Button {
    private GenesisShell.Monitor? _monitor;
    private double _dpi;

    public GenesisShell.Monitor? monitor {
      get {
        return this._monitor;
      }
      set construct {
        this._monitor = value;
      }
    }

    public double dpi {
      get {
        if (this._monitor != null) return this._monitor.dpi;
        return this._dpi;
      }
      set construct {
        this._dpi = value;
      }
    }

    public double dpi_size {
      get; set construct;
      default = 1.0;
    }

    public Button(double dpi = 91.0, double dpi_size = 1.0) {
      Object(dpi: dpi, dpi_size: dpi_size);
    }

    public Button.for_monitor(GenesisShell.Monitor monitor, double dpi_size = 1.0) {
      Object(monitor: monitor, dpi_size: dpi_size);
    }

    construct {
      this.notify["dpi"].connect(() => this.queue_resize());
      this.notify["dpi_size"].connect(() => this.queue_resize());
    }

    private int get_size() {
      return GenesisShell.Math.scale(this.dpi, this.dpi_size);
    }

    public override void get_preferred_height(out int min_height, out int nat_height) {
      min_height = nat_height = this.get_size();
    }

    public override void size_allocate(Gtk.Allocation alloc) {
      alloc.height = this.get_size();
      base.size_allocate(alloc);
    }
  }

  public class ButtonBox : Button {
    public ButtonBox(double dpi = 91.0, double dpi_size = 1.0) {
      Object(dpi: dpi, dpi_size: dpi_size);
    }

    public ButtonBox.for_monitor(GenesisShell.Monitor monitor, double dpi_size = 1.0) {
      Object(monitor: monitor, dpi_size: dpi_size);
    }

    private int get_size() {
      return GenesisShell.Math.scale(this.dpi, this.dpi_size);
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_size();
    }

    public override void size_allocate(Gtk.Allocation alloc) {
      alloc.width = this.get_size();
      base.size_allocate(alloc);
    }
  }
}
