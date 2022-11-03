namespace GenesisShellGtk3 {
  namespace DashIndicators {
    public class WiFi : GenesisShellGtk3.DashIndicator, GLib.AsyncInitable {
      private NM.Client _client;
      private ulong _enable_id;
      private ulong _added_id;
      private ulong _removed_id;

      public NM.DeviceWifi? device { get; }

      public async WiFi(GenesisShell.Monitor monitor, string id, int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable ?cancellable = null) throws GLib.Error {
        Object(monitor: monitor, id: id);
        yield this.init_async(io_pri, cancellable);
      }

      ~WiFi() {
        if (this._enable_id > 0) {
          this._client.disconnect(this._enable_id);
          this._enable_id = 0;
        }

        if (this._added_id > 0) {
          this._client.disconnect(this._added_id);
          this._added_id = 0;
        }

        if (this._removed_id > 0) {
          this._client.disconnect(this._removed_id);
          this._removed_id = 0;
        }
      }

      construct {
        this.no_show_all = true;
        this.icon.icon_name = "network-wireless";
      }

      public async bool init_async(int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable ?cancellable = null) throws GLib.Error {
        this._client = yield NM.Client.new_async(cancellable);
        this._client.bind_property("wireless-enabled", this, "active", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);

        this._enable_id = this._client.notify["wireless-enabled"].connect(() => {
          this.update_device();
        });

        this._added_id = this._client.device_added.connect((device) => {
          this.update_device();
        });

        this._removed_id = this._client.device_removed.connect((device) => {
          if (this._device != null) {
            if (this._device.get_iface() == device.get_iface()) {
              this._device = null;
              this.hide();
            }
          }
        });

        this.update_device();
        return true;
      }

      private void update_device() {
        if (this._device == null) {
          foreach (var dev in this._client.get_all_devices()) {
            if (dev is NM.DeviceWifi) {
              this._device = (NM.DeviceWifi)dev;
              break;
            }
          }
        }

        if (this._device == null) this.hide();
        else {
          this.show();
          this.icon.show();
        }
      }

      public override void realize() {
        base.realize();
        this.update_device();
      }
    }
  }
}
