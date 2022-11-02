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
    public DesktopWidget ?widget { get; }

    public bool is_wayland {
      get {
#if HAS_GTK3_WAYLAND
        return this.get_display() is Gdk.Wayland.Display;
#else
        return false;
#endif
      }
    }

    public bool is_x11 {
      get {
#if HAS_GTK3_X11
        return this.get_display() is Gdk.X11.Display;
#else
        return false;
#endif
      }
    }

    public bool should_resize {
      get {
#if HAS_GTK_LAYER_SHELL
        if (this.is_wayland) {
          switch (this.context.mode) {
          case GenesisShell.ContextMode.BIG_PICTURE:
            return true;

          case GenesisShell.ContextMode.GADGETS:
            return false;

          default:
            return true;
          }
        }
        return true;
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
      this._widget           = new DesktopWidget(this.monitor);

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
#if HAS_GTK_LAYER_SHELL
        if (this.is_wayland) {
          var monitor = this.monitor as Monitor;
          assert(monitor != null);

          GtkLayerShell.init_for_window(this);
          GtkLayerShell.set_monitor(this, monitor.gdk_monitor);
          GtkLayerShell.set_layer(this, GtkLayerShell.Layer.BACKGROUND);
          GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);
          GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.RIGHT, true);
          GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
          GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
          GtkLayerShell.set_exclusive_zone(this, -1);
          GtkLayerShell.set_namespace(this, "genesis-shell-desktop");
          GLib.debug(_("Gtk layer shell is active on %p"), this);
        }
#endif

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

    private void update_position() {
      this.move(this.monitor.x, this.monitor.y);
    }

    private void update_mode() {
      if (this.should_resize) {
        this.default_width  = this.monitor.mode.width;
        this.default_height = this.monitor.mode.height;
        this.resize(this.monitor.mode.width, this.monitor.mode.height);
      }

      this.queue_resize();
    }
  }
}
