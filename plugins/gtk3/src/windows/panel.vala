namespace GenesisShellGtk3 {
  public sealed class PanelWindow : TokyoGtk.Window {
    private ulong _x_id;
    private ulong _y_id;
    private ulong _mode_id;

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }
    public PanelWidget widget { get; }

    public bool is_wayland {
      get {
#if HAS_GTK3_WAYLAND
        return this.get_display() is Gdk.Wayland.Display;
#else
        return false;
#endif
      }
    }

    internal PanelWindow(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    ~PanelWindow() {
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
      this._widget           = new PanelWidget(this.monitor);

#if HAS_GTK_LAYER_SHELL
      if (this.is_wayland) {
        var monitor = this.monitor as Monitor;
        assert(monitor != null);

        GtkLayerShell.init_for_window(this);
        GtkLayerShell.auto_exclusive_zone_enable(this);
        GtkLayerShell.set_monitor(this, monitor.gdk_monitor);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.RIGHT, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);

        var edge = this.monitor.mode.width * 0.01;
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, (int)(edge / 2));
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.RIGHT, (int)(edge / 2));
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.TOP, 5);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 5);

        GtkLayerShell.set_namespace(this, "genesis-shell-panel");
        GLib.debug(_("Gtk layer shell is active on %p"), this);
      }
#endif

      this.type_hint = Gdk.WindowTypeHint.DOCK;

      this._x_id = this.monitor.notify["x"].connect(() => {
        this.update_position();
      });

      this._y_id = this.monitor.notify["y"].connect(() => {
        this.update_position();
      });

      this._mode_id = this.monitor.notify["mode"].connect(() => {
        var edge = this.monitor.mode.width * 0.01;
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, (int)(edge / 2));
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.RIGHT, (int)(edge / 2));
        this.queue_resize();
      });

      this.update_position();

      this.get_box().add(this.widget);
      this.show_all();
      this.header.hide();
    }

    private int get_width() {
      int min;
      int nat;
      this.widget.get_preferred_width(out min, out nat);
      return nat;
    }

    private int get_height() {
      int min;
      int nat;
      this.widget.get_preferred_height(out min, out nat);
      return nat;
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_width();
    }

    public override void get_preferred_height(out int min_height, out int nat_height) {
      min_height = nat_height = this.get_height();
    }

    private void update_position() {
      var edge = this.monitor.mode.width * 0.01;
      this.move(this.monitor.x + (int)(edge / 2), this.monitor.y + 5);
    }
  }
}
