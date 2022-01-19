namespace GenesisWidgets {
  [GtkTemplate(ui = "/com/expidus/genesis/libwidgets/net.glade")]
  public class WiFiNetworkItem : Gtk.ListBoxRow {
    [GtkChild]
    private unowned Gtk.Image security_icon;

    [GtkChild]
    private unowned Gtk.Label network_name;

    [GtkChild]
    private unowned Gtk.Image connected_icon;
    
    public NM.AccessPoint access_point { get; construct; }
    public bool is_connected { get; construct; default = false; }
    
    public string access_point_name {
      owned get {
        var arr = this.access_point.get_ssid();
        if (arr != null) {
          var sb = new GLib.StringBuilder.sized(arr.length);
          foreach (var ch in arr.get_data()) sb.append_c((char)ch);
          return sb.str;
        }
        return this.access_point.get_bssid();
      }
    }
    
    public WiFiNetworkItem(NM.AccessPoint ap, bool connected = false) {
      Object(access_point: ap, is_connected: connected);
    }
    
    construct {
      this.show_all();
      
      if (this.is_connected) this.connected_icon.show_all();
      else this.connected_icon.hide();
      
      if (this.access_point.flags == NM.80211ApFlags.NONE) {
        this.security_icon.hide();
      } else {
        this.security_icon.show_all();
      }
      
      this.network_name.label = this.access_point_name;
    }
  }

  public class NetworkPanelIcon : Gtk.Box, GLib.AsyncInitable {
    private NM.Client _client;
    private MM.Manager? _mm;
    private NM.DeviceWifi? _wifi;
    private NM.DeviceEthernet? _eth;

    private ulong _wifi_id;
    private ulong _eth_id;
    
    private Gtk.Image _wifi_icon;
    private Gtk.Image _eth_icon;
    private Gtk.Image _cell_icon;

    private GLib.TimeoutSource _timeout;
    
    construct {
      this._wifi_icon = new Gtk.Image.from_icon_name("network-wireless-offline", Gtk.IconSize.LARGE_TOOLBAR);
      this.add(this._wifi_icon);

      this._eth_icon = new Gtk.Image.from_icon_name("network-wired-offline", Gtk.IconSize.LARGE_TOOLBAR);
      this.add(this._eth_icon);

      this._cell_icon = new Gtk.Image.from_icon_name("network-cellular-offline", Gtk.IconSize.LARGE_TOOLBAR);
      this.add(this._cell_icon);
      
      this.show_all();

      this._timeout = new GLib.TimeoutSource.seconds(5);
      this._timeout.set_callback(() => {
        if (this._client != null) this.update();
        return true;
      });
      this._timeout.attach(GLib.MainContext.@default());
    }

    public override async bool init_async(int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable? cancellable = null) throws GLib.Error {
      this._client = yield NM.Client.new_async(cancellable);
      try {
        this._mm = yield new MM.Manager(this._client.dbus_connection, GLib.DBusObjectManagerClientFlags.NONE, cancellable);
      } catch (GLib.Error e) {
        this._mm = null;
      }
      this.update();
      return true;
    }
    
    private MM.Modem? find_modem() {
      if (this._mm == null) return null;

      unowned var obj = this._mm.get_objects().first();
      if (obj == null) return null;

      return ((MM.Object)obj).get_modem();
    }
    
    private NM.Device? find_device(NM.DeviceType type) {
      for (var i = 0; i < this._client.all_devices.length; i++) {
        var device = this._client.all_devices.get(i);
        if (device.device_type == type) return device;
      }
      return null;
    }
    
    private void update() {
      var wifi = this.find_device(NM.DeviceType.WIFI) as NM.DeviceWifi;
      var eth = this.find_device(NM.DeviceType.ETHERNET) as NM.DeviceEthernet;
      var cell = this.find_device(NM.DeviceType.MODEM) as NM.DeviceModem;

      if (wifi != this._wifi) {
        if (this._wifi == null && wifi != null) {
          this._wifi_id = wifi.state_changed.connect((n, o, r) => {
            if (n != o) {
              switch (n) {
                case NM.DeviceState.PREPARE:
                  this._wifi_icon.icon_name = "network-wireless-acquiring";
                  break;
                case NM.DeviceState.FAILED:
                  this._wifi_icon.icon_name = "network-wireless-offline";
                  break;
                case NM.DeviceState.UNAVAILABLE:
                  this._wifi_icon.icon_name = "network-wireless-no-route";
                  break;
              }
            }
          });
        } else {
          ((GLib.Object)this._wifi).disconnect(this._wifi_id);
        }

        this._wifi = wifi;
      }
      
      if (eth != this._eth) {
        if (this._eth == null && eth != null) {
          this._eth_id = eth.state_changed.connect((n, o, r) => {
            if (n != o) {
              switch (n) {
                case NM.DeviceState.PREPARE:
                  this._eth_icon.icon_name = "network-wired-acquiring";
                  break;
                case NM.DeviceState.FAILED:
                  this._eth_icon.icon_name = "network-wired-offline";
                  break;
                case NM.DeviceState.UNAVAILABLE:
                  this._eth_icon.icon_name = "network-wired-no-route";
                  break;
                case NM.DeviceState.ACTIVATED:
                  this._eth_icon.icon_name = "network-wired-activated";
                  break;
              }
            }
          });
        }
      }

      if (wifi != null) {
        this._wifi_icon.show();
        
        if (wifi.active_access_point == null) this._wifi_icon.icon_name = "network-wireless-offline";
        else { 
          var strength = wifi.active_access_point.get_strength();
            
          if (strength == 0) this._wifi_icon.icon_name = "network-wireless-signal-none";
          else if (strength < 30) this._wifi_icon.icon_name = "network-wireless-signal-weak";
          else if (strength < 70) this._wifi_icon.icon_name = "network-wireless-signal-ok";
          else if (strength < 90) this._wifi_icon.icon_name = "network-wireless-signal-good";
          else this._wifi_icon.icon_name = "network-wireless-signal-excellent";
        }
      } else {
        this._wifi_icon.hide();
      }
      
      if (eth != null && eth.carrier) {
        this._eth_icon.show();
        this._eth_icon.icon_name = "network-wired";
      } else {
        this._eth_icon.hide();
      }
      
      var modem = this.find_modem();
      if (cell != null && this._mm != null && modem != null) {
        this._cell_icon.show();
        
        if (cell.active_connection == null) this._cell_icon.icon_name = "network-cellular-offline";
        else {
          this._cell_icon.icon_name = "network-cellular-connected";
          bool recent = false;
          var strength = modem.get_signal_quality(out recent);
          if (strength >= 90) this._cell_icon.icon_name = "network-cellular-signal-excellent";
          else if (strength >= 70) this._cell_icon.icon_name = "network-cellular-signal-good";
          else if (strength >= 50) this._cell_icon.icon_name = "network-cellular-signal-ok";
          else if (strength >= 25) this._cell_icon.icon_name = "network-cellular-signal-low";
          else this._cell_icon.icon_name = "network-cellular-signal-none";
        }
      } else {
        this._cell_icon.hide();
      }
    }
  }
}