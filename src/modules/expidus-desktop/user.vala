namespace ExpidusDesktop {
  [GtkTemplate(ui = "/com/expidus/genesis/module/expidus-desktop/dialogs.glade")]
  public class WiFiPasswordDialog : Hdy.Window {
    [GtkChild]
    private unowned Gtk.Label label;
    
    [GtkChild]
    private unowned Gtk.Entry password;
    
    public bool did_fail { get; construct; default = false; }
    public string network_name { get; construct; }
    
    public static async string? new_async(string network_name, bool did_fail = false) {
      GLib.SourceFunc cb = new_async.callback;
      string? res = null;

      var self = new WiFiPasswordDialog(network_name, did_fail);
      self.done.connect((result) => {
        res = result;
        cb();
      });
      
      self.show_all();
      yield;
      return res;
    }
    
    public WiFiPasswordDialog(string network_name, bool did_fail = false) {
      Object(network_name: network_name, did_fail: did_fail);
    }
    
    construct {
      if (this.did_fail) {
        this.label.label = "Password failed, please enter password again for %s".printf(this.network_name);
      } else {
        this.label.label = "Connect to network \"%s\"".printf(this.network_name);
      }
    }
    
    [GtkCallback]
    private void do_cancel() {
      this.done(null);
      this.hide();
    }
    
    [GtkCallback]
    private void do_connect() {
      this.done(this.password.text);
      this.hide();
    }
    
    public signal void done(string? result);
  }

  [GtkTemplate(ui = "/com/expidus/genesis/module/expidus-desktop/user.glade")]
  public class UserDashboard : GenesisWidgets.LayerWindow {
    private PulseAudio.GLibMainLoop _pa_main_loop;
    private PulseAudio.Context _pa_ctx;
    private GWeather.Info _gw_info;
    private NM.Client _nm_client;
    private GLib.TimeoutSource _timeout;
    private Up.Client _up_client;
    private Playerctl.PlayerManager _player_manager;
    private Playerctl.Player? _player;
    private GenesisLogind.Manager _login_manager;
    private GenesisBluetooth.Manager _bt_manager;
    
    [GtkChild]
    private unowned Gtk.ToggleButton status_wifi_btn;
    
    [GtkChild]
    private unowned Gtk.ToggleButton status_bluetooth_btn;

    [GtkChild]
    private unowned Gtk.Box volume_box;
    
    [GtkChild]
    private unowned Gtk.Scale volume_slider;

    [GtkChild]
    private unowned Hdy.ExpanderRow wifi_network_select;
    
    [GtkChild]
    private unowned Gtk.ListBox wifi_networks_list;
    
    [GtkChild]
    private unowned Hdy.ExpanderRow bluetooth_device_select;
    
    [GtkChild]
    private unowned Gtk.ListBoxRow battery_status;
    
    [GtkChild]
    private unowned Gtk.Image battery_icon;
    
    [GtkChild]
    private unowned Gtk.Label battery_label_percent;
    
    [GtkChild]
    private unowned Gtk.Label battery_charge_time;
    
    [GtkChild]
    private unowned Gtk.ListBoxRow music_controls;

    [GtkChild]
    private unowned Gtk.Label music_title;

    [GtkChild]
    private unowned Gtk.Label music_subtitle;
    
    [GtkChild]
    private unowned Gtk.Image music_play_icon;
    
    [GtkChild]
    private unowned Gtk.Stack weather_stack;
    
    [GtkChild]
    private unowned GWeather.LocationEntry weather_search;
    
    [GtkChild]
    private unowned Gtk.Image weather_icon;
    
    [GtkChild]
    private unowned Gtk.Label weather_location;
    
    [GtkChild]
    private unowned Gtk.Label weather_temp;
    
    [GtkChild]
    private unowned Gtk.Label weather_wind;
    
    public UserDashboard(GenesisComponent.Monitor monitor) {
      Object(application: monitor.shell.application, monitor_name: monitor.name, layer: GtkLayerShell.Layer.TOP);
    }
    
    ~UserDashboard() {
      // TODO: figure out why destructor isn't called
      if (this._pa_ctx != null) {
        this._pa_ctx.disconnect();
        this._pa_ctx = null;
      }
      
      if (this._timeout != null) {
        GLib.Source.remove(this._timeout.get_id());
        this._timeout.destroy();
        this._timeout = null;
      }
    }

    construct {
      var settings = new GLib.Settings("com.expidus.genesis.desktop");

      this._pa_main_loop = new PulseAudio.GLibMainLoop(GLib.MainContext.@default());
      this._gw_info = new GWeather.Info(this.weather_search.location);
      this._gw_info.set_enabled_providers(GWeather.Provider.ALL);
      this._gw_info.set_contact_info("inquiry@midstall.com");
      this._gw_info.set_application_id("com.expidus.genesis");

      this.weather_search.notify["location"].connect(() => {
        if (this.weather_search.location != null) {
          var v = this.weather_search.location.serialize();
          settings.set_value("weather-locations", new GLib.Variant.array(v.get_type(), { v }));
          this._gw_info.location = this.weather_search.location;
          this.weather_stack.set_visible_child_name("weather");
          this._gw_info.update();
        } else {
          this.weather_stack.set_visible_child_name("placeholder");
        }
      });
      
      this._gw_info.updated.connect(() => {
        if (this._gw_info.location != null) {
          this.weather_icon.icon_name = this._gw_info.get_icon_name();
          this.weather_location.label = this._gw_info.get_location_name();
          this.weather_temp.label = this._gw_info.get_temp();
          this.weather_wind.label = this._gw_info.get_wind();
        }
      });
      
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
      GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.RIGHT, true);

      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.TOP, 8);
      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 8);
      GtkLayerShell.set_margin(this, GtkLayerShell.Edge.RIGHT, 15);
      
      GtkLayerShell.set_keyboard_mode(this, GtkLayerShell.KeyboardMode.EXCLUSIVE);
      
      if (settings.get_value("weather-locations").n_children() > 0) {
        var loc = GWeather.Location.get_world().deserialize(settings.get_value("weather-locations").get_child_value(0));
        this.weather_search.location = loc;
        this._gw_info.location = loc;
      }
      
      try {
        this._login_manager = new GenesisLogind.Manager();
      } catch (GLib.Error e) {}
      
      try {
        this._up_client = new Up.Client.full(null);
        this.battery_status.show_all();
        this.battery_update();
      } catch (GLib.Error e) {
        this.battery_status.hide();
      }
      
      try {
        this._player_manager = new Playerctl.PlayerManager();

        this._player_manager.name_appeared.connect((name) => {
          if (this._player == null) {
            try {
              this._player = new Playerctl.Player.from_name(name.copy());
              this._player_manager.manage_player(this._player);
            } catch (GLib.Error e) {}
          }
        });
        this._player_manager.name_vanished.connect((name) => {
          if (this._player != null && this._player.player_name == name.name && this._player.source == name.source) {
            this._player = null;
          }
        });

        var name = this._player_manager.player_names.nth_data(0);
        if (name != null) {
          try {
            this._player = new Playerctl.Player.from_name(name.copy());
            this._player_manager.manage_player(this._player);
          } catch (GLib.Error e) {}
        }

        this.player_update();
      } catch (GLib.Error e) {
        this.music_controls.hide();
      }
      
      try {
        this._bt_manager = new GenesisBluetooth.Manager();
        var adapter = this._bt_manager.adapters.nth_data(0);
        if (adapter != null) {
          this.status_bluetooth_btn.set_active(adapter.powered);
        }

        this.bt_update();
      } catch (GLib.Error e) {
        this.bluetooth_device_select.hide();
        this.status_bluetooth_btn.hide();
      }

      this._timeout = new GLib.TimeoutSource.seconds(1);
      this._timeout.set_callback(() => {
        if (this._nm_client != null) this.net_update();
        if (this._player_manager != null) this.player_update();
        if (this._up_client != null) this.battery_update();
        if (this._bt_manager != null) this.bt_update();
        return true;
      });
      this._timeout.attach(GLib.MainContext.@default());

      this.pulse_init.begin(null, (obj, res) => {
        try {
          if (!this.pulse_init.end(res)) this.volume_box.hide();
        } catch (GLib.Error e) {
          this.volume_box.hide();
        }
      });

      this.net_init.begin(null, (obj, res) => {
        try {
          if (!this.net_init.end(res)) {
            this.wifi_network_select.hide();
            this.status_wifi_btn.hide();
          } else {
            this.status_wifi_btn.set_active(this._nm_client.wireless_enabled);
          }
        } catch (GLib.Error e) {
          this.wifi_network_select.hide();
          this.status_wifi_btn.hide();
        }
      });
    }
    
    private void bt_update() {
      try {
        if (this._bt_manager != null) {
          this.bluetooth_device_select.show();
          this.status_bluetooth_btn.show();

          var adapter = this._bt_manager.adapters.nth_data(0);
          if (adapter != null) {
            var conn = this._bt_manager.find_connected(adapter);
            if (conn != null) {
              this.bluetooth_device_select.subtitle = "Connected to %s".printf(conn.name);
            } else if (adapter.powered) {
              this.bluetooth_device_select.subtitle = "Found %u devices".printf(this._bt_manager.devices.length());
            } else {
              this.bluetooth_device_select.subtitle = "Bluetooth Off";
            }
          } else {
            this.bluetooth_device_select.hide();
            this.status_bluetooth_btn.hide();
          }
        }
      } catch (GLib.Error e) {}
    }
    
    private async bool pulse_init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      GLib.SourceFunc cb = pulse_init.callback;
      this._pa_ctx = new PulseAudio.Context(this._pa_main_loop.get_api(), null);
      var ret = false;
      var connected = false;
      GLib.Error? error = null;

      this._pa_ctx.set_state_callback((c) => {
        switch (c.get_state()) {
          case PulseAudio.Context.State.FAILED:
          case PulseAudio.Context.State.TERMINATED:
            if (!connected) {
              GLib.Timeout.add_seconds(1, () => {
                this.pulse_init.begin(cancellable, (obj, res) => {
                  try {
                    ret = this.pulse_init.end(res);
                  } catch (GLib.Error e) {
                    error = e;
                  }
                  GLib.Idle.add((owned) cb);
                });
                return false;
              });
            }
            break;
          case PulseAudio.Context.State.READY:
            error = null;
            ret = true;
            this._pa_ctx.set_subscribe_callback((c, t, i) => {
              switch (t & PulseAudio.Context.SubscriptionEventType.FACILITY_MASK) {
                case PulseAudio.Context.SubscriptionEventType.SERVER:
                  this.pulse_update();
                  break;
                case PulseAudio.Context.SubscriptionEventType.SINK:
                  this.pulse_update();
                  break;
                default:
                  break;
              }
            });
            this._pa_ctx.subscribe(PulseAudio.Context.SubscriptionMask.SERVER | PulseAudio.Context.SubscriptionEventType.CARD | PulseAudio.Context.SubscriptionEventType.SINK, null);
            this.pulse_update();
            GLib.Idle.add((owned) cb);
            break;
          default:
            break;
        }
      });

      if (this._pa_ctx.connect(null, PulseAudio.Context.Flags.NOFAIL, null) < 0) {
        return false;
      }

      yield;
      if (error != null) throw error;
      return ret;
    }

    private void pulse_update() {
      if (this._pa_ctx != null) {
        this._pa_ctx.get_server_info((c, server_info) => {
          c.get_sink_info_by_name(server_info.default_sink_name, (c2, sink_info) => {
            if (sink_info != null) {
              var v = sink_info.volume.avg();
              if (v > PulseAudio.Volume.NORM) v = PulseAudio.Volume.NORM;
              var muted = sink_info.mute == 0 ? false : true;
              var volume = (v * 1.0) / PulseAudio.Volume.NORM;
           
              if (muted) this.volume_slider.set_value(0.0);
              else this.volume_slider.set_value(volume);
            }
          });
        });
      }
    }
    
    private void pulse_set() { 
      if (this._pa_ctx != null) {
        this._pa_ctx.get_server_info((c, server_info) => {
          c.get_sink_info_by_name(server_info.default_sink_name, (c2, sink_info) => {
            if (sink_info != null) {
              var vol = PulseAudio.CVolume();
              vol.set(sink_info.volume.channels, (uint32)((this.volume_slider.get_value() * PulseAudio.Volume.NORM) / 1.0));
              c2.set_sink_volume_by_name(sink_info.name, vol, null);
            }
          });
        });
      }
    }
    
    private NM.Device? find_device(NM.DeviceType type) {
      for (var i = 0; i < this._nm_client.all_devices.length; i++) {
        var device = this._nm_client.all_devices.get(i);
        if (device.device_type == type) return device;
      }
      return null;
    }
    
    private async bool net_init(GLib.Cancellable? cancellable = null) throws GLib.Error { 
      this._nm_client = yield NM.Client.new_async(cancellable);
      this.net_update();
      return true;
    }

    private void net_after_scan(NM.DeviceWifi wifi) {
      this.wifi_networks_list.foreach((widget) => this.wifi_networks_list.remove(widget));
      
      foreach (var ap in wifi.access_points) {
        var is_connected = false;
        if (wifi.active_access_point != null) is_connected = wifi.active_access_point.get_bssid() == ap.get_bssid();

        var row = new GenesisWidgets.WiFiNetworkItem(ap, is_connected);
        this.wifi_networks_list.add(row);

        if (is_connected) this.wifi_networks_list.select_row(row);
      }
      
      this.wifi_network_select.subtitle = "Found %d networks".printf(wifi.access_points.length);
      if (wifi.active_access_point != null) {
        var arr = wifi.active_access_point.get_ssid();
        var sb = new GLib.StringBuilder.sized(arr.length);
        foreach (var ch in arr.get_data()) sb.append_c((char)ch);
        this.wifi_network_select.subtitle = "Connected to %s".printf(sb.str);
      }
      this.wifi_network_select.enable_expansion = wifi.access_points.length > 0;
    }

    private void net_update() {
      var wifi = this.find_device(NM.DeviceType.WIFI) as NM.DeviceWifi;

      if (wifi != null && this._nm_client.wireless_hardware_enabled) {
        if (this._nm_client.wireless_enabled) {
          if (wifi.get_last_scan() == -1 || wifi.get_last_scan() >= 60000) {
            wifi.request_scan_async.begin(null, (obj, res) => {
              try {
                wifi.request_scan_async.end(res);
                this.net_after_scan(wifi);
              } catch (GLib.Error e) {}
            });
          } else {
            this.net_after_scan(wifi);
          }
        } else {
          this.wifi_network_select.subtitle = "WiFi Off";
        }
      } else {
        this.wifi_network_select.hide();
        this.status_wifi_btn.hide();
      }
    }
    
    private void player_update() {
      try {
        if (this._player != null && this._player.playback_status != Playerctl.PlaybackStatus.STOPPED) {
          this.music_controls.show_all();
          
          this.music_title.label = this._player.get_title();

          if (this._player.can_seek) {
            var seconds = this._player.get_position();
            this.music_subtitle.label = "%0.2d:%0.2d".printf((int)((seconds / 60) % 60), (int)(seconds % 60));
          } else if (this._player.get_album() != null) {
            this.music_subtitle.label = this._player.get_album();
          }
          
          if (this._player.playback_status == Playerctl.PlaybackStatus.PLAYING) {
            this.music_play_icon.icon_name = "gtk-media-pause";
          } else {
            this.music_play_icon.icon_name = "gtk-media-play";
          }
        } else {
          this.music_controls.hide();
        }
      } catch (GLib.Error e) {
        this.music_controls.hide();
      }
    }

    private void battery_update() {
      if (this._up_client != null) {
        var found = false;
        foreach (var dev in this._up_client.get_devices2()) {
          if (dev.kind == Up.DeviceKind.BATTERY) {
            var per = ((dev.energy - dev.energy_empty) / dev.energy_full) * 100;
            var icon_level = "%0.3d".printf((int)(10 * GLib.Math.round(per / 10.0)));
            var icon_suffix = "";
            
            this.battery_label_percent.label = "Battery is %0.0f%% full".printf(per);
            
            switch (dev.state) {
              case Up.DeviceState.CHARGING:
                icon_suffix = "-charging";
                var minutes = dev.time_to_full / 60;
                this.battery_charge_time.label = "%d:%0.2d until charged".printf((int)(minutes / 60), (int)(minutes % 60));
                break;
              case Up.DeviceState.DISCHARGING:
                var minutes = dev.time_to_empty / 60;
                this.battery_charge_time.label = "%d:%0.2d remaining".printf((int)(minutes / 60), (int)(minutes % 60));
                break;
              case Up.DeviceState.FULLY_CHARGED:
                this.battery_charge_time.label = "Fully charged";
                break;
              case Up.DeviceState.EMPTY:
                this.battery_charge_time.label = "Battery is empty";
                break;
              default:
                break;
            }

            this.battery_icon.icon_name = "battery-%s%s".printf(icon_level, icon_suffix);
            found = true;
            break;
          }
        }

        if (found) this.battery_status.show_all();
        else this.battery_status.hide();
      }
    }

		public override void get_preferred_width(out int min_width, out int nat_width) {
			min_width = nat_width = ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(350);
		}

		public override void get_preferred_height(out int min_height, out int nat_height) {
			min_height = nat_height = this.monitor.geometry.height - ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(5)
        - ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(35);
		}
    
    [GtkCallback]
    private void do_toggle_wifi() {
      this._nm_client.wireless_enabled = this.status_wifi_btn.get_active();
      
      if (this._nm_client.wireless_enabled) {
        this.net_update();
      } else {
        this.wifi_network_select.subtitle = "WiFi Off"; 
      }
    }
    
    [GtkCallback]
    private void do_toggle_bluetooth() {
      if (this._bt_manager != null) {
        var adapter = this._bt_manager.adapters.nth_data(0);
        if (adapter != null) {
          adapter.powered = this.status_bluetooth_btn.get_active();
          if (adapter.powered) {
            this.bt_update();
          } else {
            this.bluetooth_device_select.subtitle = "Bluetooth Off";
          }
        }
      }
    }

    [GtkCallback]
    private void do_toggle_location() {}
    
    [GtkCallback]
    private void do_toggle_dnd() {}

    [GtkCallback]
    private void volume_changed() {
      this.pulse_set();
    }
    
    [GtkCallback]
    private void brightness_changed() {}
    
    [GtkCallback]
    private void wifi_network_selected(Gtk.ListBoxRow? row) {
      var wifi = this.find_device(NM.DeviceType.WIFI) as NM.DeviceWifi;
      var item = row as GenesisWidgets.WiFiNetworkItem;
      if (item != null && wifi != null) {
        NM.RemoteConnection? use_conn = null;
        foreach (var conn in wifi.available_connections) {
          var settings = conn.get_setting_wireless();
          if (settings == null) continue;
          
          if (settings.get_bssid() == item.access_point.get_bssid()) {
            use_conn = conn;
            break;
          } else if (settings.get_ssid() != null && item.access_point.get_ssid() != null) {
            if (settings.get_ssid().compare(item.access_point.get_ssid()) == 0) {
              use_conn = conn;
              break;
            }
          }
        }
        
        if (use_conn != null) {
          var dialog = new Gtk.Dialog.with_buttons("Connect to " + item.access_point_name, this, Gtk.DialogFlags.MODAL, "Yes", Gtk.ResponseType.ACCEPT, "Cancel", Gtk.ResponseType.CLOSE);
          var content = dialog.get_content_area();
          content.add(new Gtk.Label("Would you like to connect to %s?".printf(item.access_point_name)));
          
          dialog.response.connect((id) => {
            dialog.hide();
            
            switch (id) {
              case Gtk.ResponseType.ACCEPT:
                this.wifi_network_select.subtitle = "Connecting to " + item.access_point_name;
                this._nm_client.activate_connection_async.begin(use_conn, wifi, null, null, (obj, res) => {
                  try {
                    this._nm_client.activate_connection_async.end(res);
                    this.net_after_scan(wifi);
                  } catch (GLib.Error e) {
                    var d = new Gtk.Dialog.with_buttons("Connect to " + item.access_point_name, this, Gtk.DialogFlags.MODAL, "Ok", Gtk.ResponseType.CLOSE);
                    
                    var ct = d.get_content_area();
                    ct.add(new Gtk.Label("Failed to connect to access point \"%s\" (%s:%d): %s".printf(item.access_point_name, e.domain.to_string(), e.code, e.message)));
                    d.show_all();
                  }
                });
                break;
              case Gtk.ResponseType.CLOSE:
                break;
            }
          });
          
          dialog.show_all();
        } else {
          var conn = NM.SimpleConnection.new();

          var wireless_settings = new NM.SettingWireless();
          wireless_settings.add_seen_bssid(item.access_point.get_bssid());
          wireless_settings.ssid = item.access_point.get_ssid();
                
          switch (item.access_point.mode) {
            case NM.80211Mode.ADHOC:
              wireless_settings.mode = "adhoc";
              break;
            case NM.80211Mode.AP:
              wireless_settings.mode = "ap";
              break;
            case NM.80211Mode.INFRA:
              wireless_settings.mode = "infrastructure";
              break;
            case NM.80211Mode.MESH:
              wireless_settings.mode = "mesh";
              break;
            default:
              break;
          }

          conn.add_setting(wireless_settings);
          
          var setting_conn = new NM.SettingConnection();
          setting_conn.uuid = NM.Utils.uuid_generate();
          setting_conn.id = item.access_point_name;
          setting_conn.type = "802-11-wireless";
          conn.add_setting(setting_conn);

          if (NM.80211ApFlags.PRIVACY in item.access_point.flags || NM.80211ApFlags.WPS in item.access_point.flags) {
            WiFiPasswordDialog.new_async.begin(item.access_point_name, false, (obj, res) => {
              var pword = WiFiPasswordDialog.new_async.end(res);
              
              if (pword != null) {
                var security = new NM.SettingWirelessSecurity();
                security.psk = pword;
                security.key_mgmt = "wpa-psk";
                conn.add_setting(security);

                this.wifi_network_select.subtitle = "Connecting to " + item.access_point_name;
                this._nm_client.add_connection_async.begin(conn, true, null, (obj, res) => {
                  try {
                    var nc = this._nm_client.add_connection_async.end(res);
                    this._nm_client.activate_connection_async.begin(nc, wifi, null, null, (obj, res) => {
                      try {
                        this._nm_client.activate_connection_async.end(res);
                        this.net_after_scan(wifi);
                      } catch (GLib.Error e) {
                        var d = new Gtk.Dialog.with_buttons("Connect to " + item.access_point_name, this, Gtk.DialogFlags.MODAL, "Ok", Gtk.ResponseType.CLOSE);
                    
                        var ct = d.get_content_area();
                        ct.add(new Gtk.Label("Failed to connect to access point \"%s\" (%s:%d): %s".printf(item.access_point_name, e.domain.to_string(), e.code, e.message)));
                        d.show_all();
                      }
                    });
                  } catch (GLib.Error e) { 
                    var d = new Gtk.Dialog.with_buttons("Connect to " + item.access_point_name, this, Gtk.DialogFlags.MODAL, "Ok", Gtk.ResponseType.CLOSE);

                    var ct = d.get_content_area();
                    ct.add(new Gtk.Label("Failed to connect to access point \"%s\" (%s:%d): %s".printf(item.access_point_name, e.domain.to_string(), e.code, e.message)));
                    d.show_all();   
                  }
                });
              }
            });
          } else if (NM.80211ApFlags.WPS_PIN in item.access_point.flags) {
          } else if (NM.80211ApFlags.WPS_PBC in item.access_point.flags) {
            // Ask for button
          } else {
            // Confirm user wants to connect
          }
        }
      }
    }
    
    [GtkCallback]
    private void do_prev_song() {
      try {
        if (this._player != null && this._player.can_go_previous) {
          this._player.previous();
        }
      } catch (GLib.Error e) {}
    }
    
    [GtkCallback]
    private void do_pause_song() {
      try {
        if (this._player != null && (this._player.can_pause || this._player.can_play)) {
          this._player.play_pause();
          
          if (this._player.playback_status == Playerctl.PlaybackStatus.PLAYING) {
            this.music_play_icon.icon_name = "gtk-media-pause";
          } else {
            this.music_play_icon.icon_name = "gtk-media-play";
          }
        }
      } catch (GLib.Error e) {}
    }
    
    [GtkCallback]
    private void do_next_song() {
      try {
        if (this._player != null && this._player.can_go_next) {
          this._player.next();
        }
      } catch (GLib.Error e) {}
    }
    
    [GtkCallback]
    private void do_settings() {}
    
    [GtkCallback]
    private void do_logout() { 
      try {
        GLib.Bus.get_sync(GLib.BusType.SYSTEM, null).call_sync("org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "Terminate", null, null, GLib.DBusCallFlags.NONE, 0, null);
      } catch (GLib.Error e) {
        // TODO: send shutdown command to shell
      }
    }

    [GtkCallback]
    private void do_switch_user() {
      try {
        GLib.Bus.get_sync(GLib.BusType.SYSTEM, null).call_sync("org.freedesktop.login1", "/org/freedesktop/login1/seat/auto", "org.freedesktop.login1.Seat", "SwitchTo", new GLib.Variant("(u)", 1), null, GLib.DBusCallFlags.NONE, 0, null);
      } catch (GLib.Error e) {}
    }

    [GtkCallback]
    private void do_poweroff() {
      try {
        if (this._login_manager != null && this._login_manager.can_power_off) this._login_manager.poweroff(false);
      } catch (GLib.Error e) {
        GLib.warning("Failed to shutdown (%s:%d): %s", e.domain.to_string(), e.code, e.message);
      }
    }

    [GtkCallback]
    private void do_reboot() {
      try {
        if (this._login_manager != null && this._login_manager.can_reboot) this._login_manager.reboot(false);
      } catch (GLib.Error e) {
        GLib.warning("Failed to reboot (%s:%d): %s", e.domain.to_string(), e.code, e.message);
      }
    }
  }
}