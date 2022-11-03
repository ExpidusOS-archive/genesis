namespace GenesisShellGtk3 {
  public class Icon : Gtk.Image {
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

    public Icon(string icon_name, double dpi = 91.0, double dpi_size = 1.0) {
      Object(icon_name: icon_name, dpi: dpi, dpi_size: dpi_size);
    }

    public Icon.for_monitor(string icon_name, GenesisShell.Monitor monitor, double dpi_size = 1.0) {
      Object(icon_name: icon_name, monitor: monitor, dpi_size: dpi_size);
    }

    construct {
      this.pixel_size = this.get_size();

      this.notify["dpi"].connect(() => {
        this.pixel_size = this.get_size();
        this.queue_resize();
      });

      this.notify["dpi_size"].connect(() => {
        this.pixel_size = this.get_size();
        this.queue_resize();
      });
    }

    private int get_size() {
      return GenesisShell.Math.scale(this.dpi, this.dpi_size);
    }

    public override void get_preferred_height(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_size();
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_size();
    }
  }
}
