namespace GenesisShellGtk3 {
  public sealed class DesktopWindow : TokyoGtk.Window {
    private ulong _x_id;
    private ulong _y_id;
    private ulong _mode_id;

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }
    public DesktopWidget widget { get; }

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

    internal DesktopWindow(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    ~DesktopWindow() {
      if (this._x_id > 0) {
        this.monitor.disconnect(this._x_id);
        this._x_id = 0;
      }

      if (this._y_id > 0) {
        this.monitor.disconnect(this._y_id);
        this._y_id = 0;
      }

      if (this._mode_id > 0) {
        this.monitor.disconnect(this._mode_id);
        this._mode_id = 0;
      }
    }

    construct {
      this.decorated         = false;
      this.skip_pager_hint   = true;
      this.skip_taskbar_hint = true;
      this._widget = new DesktopWidget(this.monitor);

#if HAS_GTK_LAYER_SHELL
      if (!this.should_resize) {
        var monitor = this.monitor as Monitor;
        assert(monitor != null);

        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_monitor(this, monitor.gdk_monitor);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.BACKGROUND);
      }
#endif

      if (this.context.mode == GenesisShell.ContextMode.BIG_PICTURE) {
        var monitor = this.monitor as Monitor;
        assert(monitor != null);

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
      } else {
        this.type_hint = Gdk.WindowTypeHint.DESKTOP;
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

      this.update_mode();
      this.update_position();

      this.get_box().add(this.widget);
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
      }
    }
  }
}
