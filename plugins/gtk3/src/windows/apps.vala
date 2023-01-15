namespace GenesisShellGtk3 {
  public sealed class AppsWindow : TokyoGtk.Window {
    private ulong _x_id;
    private ulong _y_id;
    private ulong _mode_id;

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }
    public AppsWidget widget { get; }

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

    internal AppsWindow(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    construct {
      this.decorated         = false;
      this.skip_pager_hint   = true;
      this.skip_taskbar_hint = true;
      this._widget           = new AppsWidget(this.monitor);
      this._widget.bind_property("visible", this, "visible", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);

#if HAS_GTK_LAYER_SHELL
      if (this.is_wayland) {
        var monitor = this.monitor as Monitor;
        assert(monitor != null);

        GtkLayerShell.init_for_window(this);
        //GtkLayerShell.auto_exclusive_zone_enable(this);
        GtkLayerShell.set_monitor(this, monitor.gdk_monitor);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);

        var edge = this.monitor.mode.width * 0.01;
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, (int)(edge / 2));
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 5);

        GtkLayerShell.set_namespace(this, "genesis-shell-apps");
        GLib.debug(_("Gtk layer shell is active on %p"), this);
      }
#endif

      this._x_id = this.monitor.notify["x"].connect(() => {
        this.update_position();
      });

      this._y_id = this.monitor.notify["y"].connect(() => {
        this.update_position();
      });

      this._mode_id = this.monitor.notify["mode"].connect(() => {
#if HAS_GTK_LAYER_SHELL
        if (this.is_wayland) {
          var edge = this.monitor.mode.width * 0.01;
          GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, (int)(edge / 2));
        }
#endif

        this.update_size();
        this.queue_resize();
      });

      this.update_size();
      this.update_position();

      this.get_box().add(this.widget);
      this.header.hide();

      this.default_width = this.get_width();
      this.default_height = this.get_height();
    }

    private int get_width() {
      if (this._widget == null) return 0;
      int min;
      int nat;
      this.widget.get_preferred_width(out min, out nat);
      return nat;
    }

    private int get_height() {
      if (this._widget == null) return 0;

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

    public override void size_allocate(Gtk.Allocation alloc) {
      var monitor = this.monitor as Monitor;
      assert(monitor != null);

      int min_height;
      int nat_height;
      monitor.panel_widget.get_preferred_height(out min_height, out nat_height);

      var edge = this.monitor.mode.width * 0.01;
      alloc.x = this.monitor.x - (int)(edge / 2);
      alloc.y = this.monitor.y + min_height + 10;

      alloc.width = this.get_width();
      alloc.height = this.get_height();
      base.size_allocate(alloc);
    }

    private void update_size() {
      if (this.is_x11) {
        this.resize(this.get_width(), this.get_height());
      }
    }

    private void update_position() {
      var monitor = this.monitor as Monitor;
      assert(monitor != null);

      int min_height;
      int nat_height;
      monitor.panel_widget.get_preferred_height(out min_height, out nat_height);

      var edge = this.monitor.mode.width * 0.01;
      this.move(this.monitor.x - (int)(edge / 2), this.monitor.y + min_height + 10);
    }

    public override void map() {
      base.map();

      this.update_size();
      this.update_position();
    }
  }
}
