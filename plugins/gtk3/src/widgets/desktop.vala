namespace GenesisShellGtk3 {
  public sealed class DesktopWidget : Gtk.Box {
    private ulong _mode_id;
    private ulong _wallpaper_id;

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }
    public Gdk.Pixbuf? wallpaper { get; }

    public PanelWidget? panel { get; }

    internal DesktopWidget(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    ~DesktopWidget() {
      if (this._mode_id > 0) {
        this.monitor.disconnect(this._mode_id);
        this._mode_id = 0;
      }

      if (this._wallpaper_id > 0) {
        this.monitor.disconnect(this._wallpaper_id);
        this._wallpaper_id = 0;
      }
    }

    construct {
      this.get_style_context().add_class("genesis-shell-desktop");

      this._mode_id = this.monitor.notify["mode"].connect(() => {
        this.update_wallpaper();
      });

      this._wallpaper_id = this.monitor.notify["wallpaper"].connect(() => {
        this.update_wallpaper();
      });

      this.update_wallpaper();

      if (this.context.mode == GenesisShell.ContextMode.BIG_PICTURE) {
        this._panel = new PanelWidget(this.monitor);
        this.add(this.panel);
      }

      this.orientation = Gtk.Orientation.VERTICAL;

      this.hexpand = true;
      this.vexpand = true;
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

    public override bool draw(Cairo.Context cr) {
      if (this.wallpaper != null) {
        Gdk.cairo_set_source_pixbuf(cr, this.wallpaper, 0, 0);
        cr.paint();
      }
      return base.draw(cr);
    }

    private void update_wallpaper() {
      try {
        this._wallpaper = new Gdk.Pixbuf.from_file_at_scale(this.monitor.wallpaper, this.monitor.mode.width, this.monitor.mode.height, true);

        var width = this.wallpaper.width;
        var height = this.wallpaper.height;

        if (width != this.monitor.mode.width || height != this.monitor.mode.height) {
          var scale_width = (this.monitor.mode.width / width) + 1.0;
          var scale_height = (this.monitor.mode.height / height) + 1.0;
          var scale_pb = new Gdk.Pixbuf.from_file_at_size(this.monitor.wallpaper, (int)(width * scale_width), (int)(height * scale_height));

          var pb = new Gdk.Pixbuf(scale_pb.colorspace, scale_pb.has_alpha, scale_pb.bits_per_sample, this.monitor.mode.width, this.monitor.mode.height);

          var x = (pb.width / 2) - (scale_pb.width / 2);
          var y = (pb.height / 2) - (scale_pb.height / 2);

          pb.fill(0);
          scale_pb.copy_options(pb);
          scale_pb.composite(pb, 0, 0, pb.width, pb.height, x, y, 1.0, 1.0, Gdk.InterpType.BILINEAR, 255);
          this._wallpaper = pb;
        }

        this.queue_draw();
      } catch (GLib.Error e) {
        GLib.critical(_("Failed to set wallpaper with scaling, falling back to lazy setting: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
        this.monitor.wallpaper = this.monitor.get_default_wallpaper();
      }
    }
  }
}
