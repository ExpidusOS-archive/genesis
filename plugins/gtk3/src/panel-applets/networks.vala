namespace GenesisShellGtk3 {
  namespace PanelApplets {
    public class NetworkIcon : GenesisShellGtk3.PanelApplet {
      private ulong _state_id;
      private ulong _ap_id;
      private ulong _ap_strength_id;

      private NM.AccessPoint ?_ap;

      public NM.Device device { get; construct; }
      public Gtk.Image icon { get; }

      public NetworkIcon(NM.Device device) {
        Object(device: device);
      }

      construct {
        GLib.debug(_("Found network device %s"), this.device.@interface);

        this._icon             = new Gtk.Image.from_icon_name("network-offline", Gtk.IconSize.LARGE_TOOLBAR);
        this._icon.no_show_all = true;
        this.add(this._icon);

        this._state_id = this.device.notify["state"].connect(() => this.update_state());
        this.update_state();

        var eth = this.device as NM.DeviceEthernet;
        if (eth != null) {
          this._icon.icon_name = "network-wired";
        }

        var wifi = this.device as NM.DeviceWifi;
        if (wifi != null) {
          this._icon.icon_name = "network-wireless";
          this._ap_id          = wifi.notify["active-access-point"].connect(() => this.update_ap());
          this.update_ap();
        }
      }

      private void update_state() {
        var eth  = this.device as NM.DeviceEthernet;
        var wifi = this.device as NM.DeviceWifi;

        switch (this.device.state) {
        case NM.DeviceState.UNAVAILABLE:
        case NM.DeviceState.UNMANAGED:
        case NM.DeviceState.UNKNOWN:
          this.icon.hide();
          break;

        case NM.DeviceState.ACTIVATED:
          this.icon.show();
          break;

        case NM.DeviceState.DISCONNECTED:
        case NM.DeviceState.DEACTIVATING:
          this.icon.show();
          if (eth != null) {
            this._icon.icon_name = "network-wired-disconnected";
          }
          if (wifi != null) {
            this._icon.icon_name = "network-wireless-offline";
          }
          break;

        case NM.DeviceState.FAILED:
          this.icon.show();
          if (eth != null) {
            this._icon.icon_name = "network-wired-error";
          }
          if (wifi != null) {
            this._icon.icon_name = "network-wireless-error";
          }
          break;

        case NM.DeviceState.CONFIG:
        case NM.DeviceState.IP_CHECK:
        case NM.DeviceState.IP_CONFIG:
        case NM.DeviceState.NEED_AUTH:
        case NM.DeviceState.PREPARE:
        case NM.DeviceState.SECONDARIES:
          this.icon.show();
          if (eth != null) {
            this._icon.icon_name = "network-wired-acquiring";
          }
          if (wifi != null) {
            this._icon.icon_name = "network-wireless-acquiring";
          }
          break;
        }
      }

      private void update_ap() {
        var wifi = this.device as NM.DeviceWifi;
        if (wifi == null) {
          return;
        }

        if (this._ap != null && wifi.active_access_point != null) {
          if (wifi.active_access_point.bssid != this._ap.bssid) {
            this._ap.disconnect(this._ap_strength_id);
            this._ap_strength_id = 0;
            this._ap             = null;
          }
        } else if (this._ap != null && wifi.active_access_point == null) {
          this._ap.disconnect(this._ap_strength_id);
          this._ap_strength_id = 0;
          this._ap             = null;
        }

        if (this._ap == null && wifi.active_access_point != null) {
          this._ap             = wifi.active_access_point;
          this._ap_strength_id = this._ap.notify["strength"].connect(() => this.update_ap_strength());
          this.update_ap_strength();
        }
      }

      private void update_ap_strength() {
        var wifi = this.device as NM.DeviceWifi;
        if (wifi == null) {
          return;
        }
        if (this._ap == null) {
          this._icon.icon_name = "network-wireless-offline";
          return;
        }

        var ssid = "";
        foreach (var c in this._ap.ssid.get_data()) {
          ssid += "%c".printf(c);
        }
        this.tooltip_text = _("%s (%d%%)").printf(ssid, this._ap.strength);

        if (this._ap.strength >= 90) {
          this._icon.icon_name = "network-wireless-signal-excellent";
        } else if (this._ap.strength >= 80) {
          this._icon.icon_name = "network-wireless-signal-good";
        } else if (this._ap.strength >= 60) {
          this._icon.icon_name = "network-wireless-signal-ok";
        } else if (this._ap.strength >= 30) {
          this._icon.icon_name = "network-wireless-signal-weak";
        } else {
          this._icon.icon_name = "network-wireless-signal-none";
        }
      }
    }

    public class Networks : GenesisShellGtk3.PanelApplet, GLib.AsyncInitable {
      private NM.Client _client;
      private Gtk.Box _icons;

      private ulong _wifi_enable_id;

      public NetworkIcon ?wifi { get; }
      public NetworkIcon ?eth { get; }

      public async Networks(GenesisShell.Monitor monitor, string id, int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable ?cancellable = null) throws GLib.Error {
        Object(monitor: monitor, id: id);
        yield this.init_async(io_pri, cancellable);
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-networks");

        this._icons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        this.add(this._icons);
      }

      public async bool init_async(int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable ?cancellable = null) throws GLib.Error {
        this._client = yield NM.Client.new_async(cancellable);

        this._wifi_enable_id = this._client.notify["wireless-enabled"].connect(() => {
          this.update_wifi();
        });

        this.update_eth();
        this.update_wifi();
        this.show_all();
        return true;
      }

      private void update_eth() {
        if (this._eth == null) {
          foreach (var dev in this._client.get_all_devices()) {
            if (dev is NM.DeviceEthernet) {
              this._eth = new NetworkIcon(dev);
              this._icons.add(this._eth);
              this._eth.show();
              break;
            }
          }
        }
      }

      private void update_wifi() {
        if (this._client.wireless_enabled && this._wifi == null) {
          foreach (var dev in this._client.get_all_devices()) {
            if (dev is NM.DeviceWifi) {
              this._wifi = new NetworkIcon(dev);
              this._icons.add(this._wifi);
              this._wifi.show();
              break;
            }
          }
        } else if (!this._client.wireless_enabled && this._wifi != null) {
          this._icons.remove(this._wifi);
          this._wifi = null;
        }
      }
    }
  }
}
