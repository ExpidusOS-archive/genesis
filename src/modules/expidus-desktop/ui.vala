namespace ExpidusDesktop {
  [GtkTemplate(ui = "/com/expidus/genesis/module/expidus-desktop/user.glade")]
  public class UserDashboard : GenesisWidgets.LayerWindow {
    private PulseAudio.GLibMainLoop _pa_main_loop;
    private PulseAudio.Context _pa_ctx;
    
    private GWeather.Info _gw_info;

    [GtkChild]
    private unowned Gtk.Box volume_box;
    
    [GtkChild]
    private unowned Gtk.Scale volume_slider;
    
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
      if (this._pa_ctx != null) {
        this._pa_ctx.disconnect();
        this._pa_ctx = null;
      }
    }

    construct {
      this._pa_main_loop = new PulseAudio.GLibMainLoop(GLib.MainContext.@default());
      this._gw_info = new GWeather.Info(this.weather_search.location);
      this._gw_info.set_enabled_providers(GWeather.Provider.ALL);
      this._gw_info.set_contact_info("inquiry@midstall.com");
      this._gw_info.set_application_id("com.expidus.genesis");

      this.weather_search.notify["location"].connect(() => {
        if (this.weather_search.location != null) {
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

      this.pulse_init.begin(null, (obj, res) => {
        try {
          if (!this.pulse_init.end(res)) this.volume_box.hide();
        } catch (GLib.Error e) {
          this.volume_box.hide();
        }
      });
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

		public override void get_preferred_width(out int min_width, out int nat_width) {
			min_width = nat_width = ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(350);
		}

		public override void get_preferred_height(out int min_height, out int nat_height) {
			min_height = nat_height = this.monitor.geometry.height - ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(5)
        - ((GenesisWidgets.Application)this.application).shell.find_monitor(this.monitor_name).dpi(35);
		}

    [GtkCallback]
    private void volume_changed() {
      this.pulse_set();
    }
    
    [GtkCallback]
    private void brightness_changed() {}
  }
}