namespace GenesisShellGtk3 {
  public class Icon : Gtk.Image {
    private GenesisShell.Monitor? _monitor;
    private ulong _dpi_id;

    public GenesisShell.Monitor? monitor {
      get {
        return this._monitor;
      }
      set construct {
        if (this._monitor != null) {
          if (this._dpi_id > 0) {
            this._monitor.disconnect(this._dpi_id);
            this._dpi_id = 0;
          }
        }

        this._monitor = value;

        if (this._monitor != null) {
          this.dpi = this._monitor.dpi;
          this._dpi_id = this._monitor.notify["dpi"].connect(() => {
            this.dpi = this._monitor.dpi;
          });
        }
      }
    }

    public double dpi {
      get; set construct;
      default = 91.0;
    }

    public double dpi_size {
      get; set construct;
      default = 1.0;
    }

    public int icon_size {
      get {
        return this.get_size();
      }
      set {
        this.dpi_size = (this.dpi / value) * 5.5;
      }
    }

    public Icon(string icon_name, double dpi = 91.0, double dpi_size = 1.0) {
      Object(icon_name: icon_name, dpi: dpi, dpi_size: dpi_size);
    }

    public Icon.for_monitor(string icon_name, GenesisShell.Monitor monitor, double dpi_size = 1.0) {
      Object(icon_name: icon_name, monitor: monitor, dpi_size: dpi_size);
    }

    ~Icon() {
      if (this._monitor != null) {
        if (this._dpi_id > 0) {
          this._monitor.disconnect(this._dpi_id);
          this._dpi_id = 0;
        }
      }
    }

    private int get_size() {
      return GenesisShell.Math.em(this.dpi, this.dpi_size);
    }

    public override void size_allocate(Gtk.Allocation alloc) {
      alloc.width = this.get_size();
      alloc.height = this.get_size();
      base.size_allocate(alloc);
    }

    public override void get_preferred_height(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_size();
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_size();
    }
  }
}
