namespace GenesisShellGtk3 {
  namespace PanelApplets {
    public class Battery : GenesisShellGtk3.PanelApplet {
      private ulong _energy_id;
      private ulong _state_id;
      private ulong _time_full_id;
      private ulong _time_empty_id;

      public Up.Device device { get; construct; }
      public Gtk.Image icon { get; }

      public Battery(GenesisShell.Monitor monitor, Up.Device device) {
        Object(monitor: monitor, device: device);
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-battery");

        GLib.debug(_("Found UPower device %s"), this.device.native_path);

        this._icon = new Icon.for_monitor("battery-missing", this.monitor, PanelWidget.UNIT_SIZE);
        this.add(this._icon);

        this._energy_id     = this.device.notify["energy"].connect(() => this.update());
        this._state_id      = this.device.notify["state"].connect(() => this.update());
        this._time_full_id  = this.device.notify["time-to-full"].connect(() => this.update());
        this._time_empty_id = this.device.notify["time-to-empty"].connect(() => this.update());
        this.update();
      }

      private void update() {
        var per         = ((this.device.energy - this.device.energy_empty) / this.device.energy_full) * 100;
        var icon_level  = "%0.3d".printf((int)(10 * GLib.Math.round(per / 10.0)));
        var icon_suffix = "";

        switch (this.device.state) {
        case Up.DeviceState.CHARGING:
          icon_suffix = "-charging";

          var minutes = this.device.time_to_full / 60;
          this.tooltip_text = _("%d:%0.2d until charged").printf((int)(minutes / 60), (int)(minutes % 60));
          break;

        case Up.DeviceState.DISCHARGING:
          icon_suffix = "-charging";

          var minutes = this.device.time_to_empty / 60;
          this.tooltip_text = _("%d:%0.2d remaining").printf((int)(minutes / 60), (int)(minutes % 60));
          break;

        case Up.DeviceState.FULLY_CHARGED:
          this.tooltip_text = _("Fully charged");
          break;

        case Up.DeviceState.EMPTY:
          this.tooltip_text = _("Battery is empty");
          break;

        default:
          break;
        }

        this.icon.icon_name = "battery-%s%s".printf(icon_level, icon_suffix);
      }

      private int get_size() {
        var value = GenesisShell.Math.scale(this.monitor.dpi, PanelWidget.UNIT_SIZE);
        var monitor = this.monitor as Monitor;
        if (monitor != null) {
          var panel = monitor.panel != null ? monitor.panel.widget : monitor.desktop.widget.panel;
          if (panel != null) {
            var style_ctx = panel.get_style_context();
            var padding = style_ctx.get_padding(style_ctx.get_state());
            value += padding.top + padding.bottom;
          }
        }
        return value;
      }

      public override void get_preferred_height(out int min_width, out int nat_width) {
        min_width = nat_width = this.get_size();
      }

      public override void get_preferred_width(out int min_width, out int nat_width) {
        min_width = nat_width = this.get_size();
      }
    }

    public class Power : GenesisShellGtk3.PanelApplet, GLib.AsyncInitable {
      private Up.Client _client;
      private Gtk.Box _icons;
      private GLib.HashTable <string, Battery> _entries;

      private ulong _added_id;
      private ulong _removed_id;

      public async Power(GenesisShell.Monitor monitor, string id, int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable ?cancellable = null) throws GLib.Error {
        Object(monitor: monitor, id: id);
        yield this.init_async(io_pri, cancellable);
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-power");

        this._entries = new GLib.HashTable <string, Battery>(GLib.str_hash, GLib.str_equal);
        this._icons   = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        this.add(this._icons);
      }

      public async bool init_async(int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable ?cancellable = null) throws GLib.Error {
        this._client = new Up.Client.full(cancellable);

        this._added_id   = this._client.device_added.connect((dev) => this.device_added(dev));
        this._removed_id = this._client.device_added.connect((dev) => this.device_removed(dev));

        foreach (var dev in yield this._client.get_devices_async(cancellable)) {
          this.device_added(dev);
        }

        this.show_all();
        return true;
      }

      private void device_added(Up.Device dev) {
        if (!this._entries.contains(dev.native_path) && dev.kind == Up.DeviceKind.BATTERY) {
          var entry = new Battery(this.monitor, dev);
          this._entries.set(dev.native_path, entry);
          this._icons.add(entry);
          entry.show_all();
        }
      }

      private void device_removed(Up.Device dev) {
        if (this._entries.contains(dev.native_path)) {
          var entry = this._entries.get(dev.native_path);
          this._icons.remove(entry);
          this._entries.remove(dev.native_path);
        }
      }
    }
  }
}