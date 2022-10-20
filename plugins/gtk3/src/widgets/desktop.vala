namespace GenesisShellGtk3 {
  public sealed class Desktop : TokyoGtk.Window {
    private ulong _x_id;
    private ulong _y_id;
    private ulong _mode_id;
    private ulong _wallpaper_id;

    public GenesisShell.Context context { get; construct; }
    public GenesisShell.Monitor monitor { get; construct; }
    public Gtk.Image wallpaper { get; }

    public bool is_wayland {
      get {
#if HAS_GTK3_WAYLAND
        return this.get_display() is Gdk.Wayland.Display;
#else
        return false;
#endif
      }
    }

    public bool should_resize {
      get {
#if HAS_GTK_LAYER_SHELL
        return !(this.is_wayland && this.context.mode != GenesisShell.ContextMode.BIG_PICTURE);
#else
        return true;
#endif
      }
    }

    internal Desktop(GenesisShell.Context context, GenesisShell.Monitor monitor) {
      Object(context: context, monitor: monitor);
    }

    ~Desktop() {
      if (this._mode_id > 0) {
        this.monitor.disconnect(this._mode_id);
        this._mode_id = 0;
      }
    }

    construct {
      var monitor = this.monitor as Monitor;
      assert(monitor != null);

      this.decorated         = false;
      this.skip_pager_hint   = true;
      this.skip_taskbar_hint = true;
      this.type_hint         = Gdk.WindowTypeHint.DESKTOP;
      this._wallpaper = new Gtk.Image();

#if HAS_GTK_LAYER_SHELL
      if (!this.should_resize) {
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_monitor(this, monitor.gdk_monitor);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.BACKGROUND);
      }
#endif

      if (this.context.mode == GenesisShell.ContextMode.BIG_PICTURE) {
        for (var i = 0; i < this.get_display().get_n_monitors(); i++) {
          var m = this.get_display().get_monitor(i);
          if (m == null) {
            continue;
          }
          if (m.geometry.equal(monitor.gdk_monitor.geometry) && m.get_model() == monitor.gdk_monitor.get_model()) {
            this.fullscreen_on_monitor(this.get_display().get_default_screen(), i);
            break;
          }
        }
      }

      this._x_id = this.monitor.notify["x"].connect(() => {
        this.update_position();
      });

      this._y_id = this.monitor.notify["y"].connect(() => {
        this.update_position();
      });

      this._mode_id = this.monitor.notify["mode"].connect(() => {
        this.update_mode();
      });

      this._wallpaper_id = this.monitor.notify["wallpaper"].connect(() => {
        this.update_wallpaper();
      });

      this.update_mode();
      this.update_position();
      this.update_wallpaper();

      this.get_box().add(this.wallpaper);
      this.show_all();
      this.header.hide();
    }

    private void update_position() {
      this.move(this.monitor.x, this.monitor.y);
    }

    private void update_mode() {
      if (this.should_resize) {
        this.default_width  = this.monitor.mode.width;
        this.default_height = this.monitor.mode.height;
        this.resize(this.monitor.mode.width, this.monitor.mode.height);
        this.update_wallpaper();
      }
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
