namespace GenesisShellGtk3 {
  public sealed class DesktopWidget : Gtk.Box {
    private ulong _mode_id;
    private ulong _wallpaper_id;

    public GenesisShell.Context context { get; construct; }
    public GenesisShell.Monitor monitor { get; construct; }
    public Gtk.Image wallpaper { get; }

    internal DesktopWidget(GenesisShell.Context context, GenesisShell.Monitor monitor) {
      Object(context: context, monitor: monitor);
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
      var monitor = this.monitor as Monitor;
      assert(monitor != null);

      this._wallpaper = new Gtk.Image();

      this._mode_id = this.monitor.notify["mode"].connect(() => {
        this.update_wallpaper();
      });

      this._wallpaper_id = this.monitor.notify["wallpaper"].connect(() => {
        this.update_wallpaper();
      });

      this.update_wallpaper();
      this.add(this.wallpaper);

      this.hexpand = true;
      this.vexpand = true;
    }

    private void update_wallpaper() {
      try {
        this.wallpaper.pixbuf = new Gdk.Pixbuf.from_file_at_scale(this.monitor.wallpaper, this.monitor.mode.width, this.monitor.mode.height, true);

        var width = this.wallpaper.pixbuf.width;
        var height = this.wallpaper.pixbuf.height;

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
          this.wallpaper.pixbuf = pb;
        }
      } catch (GLib.Error e) {
        GLib.warning(N_("Failed to set wallpaper with scaling, falling back to lazy setting: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
        this.wallpaper.file = this.monitor.wallpaper;
      }
    }
  }
}
