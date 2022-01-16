namespace GenesisWidgets {
  public errordomain VolumeError {
    FAILED
  }

  public class VolumePanelIcon : Gtk.Bin, GLib.AsyncInitable {
    private Gtk.Image _img;
    private PulseAudio.GLibMainLoop _main_loop;
    private PulseAudio.Context _ctx;

    public bool reconnect { get; set construct; default = true; }
    public GLib.MainContext? main_context { get; construct; }
    
    public VolumePanelIcon() {
      Object();
    }
    
    construct {
      this._img = new Gtk.Image.from_icon_name("audio-output-none-panel", Gtk.IconSize.LARGE_TOOLBAR);
      this.add(this._img);

      if (this.main_context == null) {
        this._main_context = GLib.MainContext.@default();
      }

      this._main_loop = new PulseAudio.GLibMainLoop(this.main_context);
    }

    public override async bool init_async(int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable? cancellable = null) throws GLib.Error {
      GLib.SourceFunc cb = init_async.callback;
      this._ctx = new PulseAudio.Context(this._main_loop.get_api(), null);
      var ret = false;
      var connected = false;
      GLib.Error? error = null;

      this._ctx.set_state_callback((c) => {
        switch (c.get_state()) {
          case PulseAudio.Context.State.FAILED:
          case PulseAudio.Context.State.TERMINATED:
            if (!connected) {
              if (!this.reconnect) {
                error = new VolumeError.FAILED("Failed to connect");
                ret = false;
                GLib.Idle.add((owned) cb);
              } else {
                GLib.Timeout.add_seconds(1, () => {
                  this.init_async.begin(io_pri, cancellable, (obj, res) => {
                    try {
                      ret = this.init_async.end(res);
                    } catch (GLib.Error e) {
                      error = e;
                    }
                    GLib.Idle.add((owned) cb);
                  });
                  return false;
                });
              }
            }
            break;
          case PulseAudio.Context.State.READY:
            error = null;
            ret = true;
            this._ctx.set_subscribe_callback((c, t, i) => {
              switch (t & PulseAudio.Context.SubscriptionEventType.FACILITY_MASK) {
                case PulseAudio.Context.SubscriptionEventType.SERVER:
                  this.update();
                  break;
                case PulseAudio.Context.SubscriptionEventType.SINK:
                  this.update();
                  break;
                default:
                  break;
              }
            });
            this._ctx.subscribe(PulseAudio.Context.SubscriptionMask.SERVER | PulseAudio.Context.SubscriptionEventType.CARD | PulseAudio.Context.SubscriptionEventType.SINK, null);
            this.update();
            GLib.Idle.add((owned) cb);
            break;
          default:
            break;
        }
      });

      if (this._ctx.connect(null, PulseAudio.Context.Flags.NOFAIL, null) < 0) {
        return false;
      }

      yield;
      if (error != null) throw error;
      return ret;
    }
    
    private void update() {
      this._ctx.get_server_info((c, server_info) => {
        c.get_sink_info_by_name(server_info.default_sink_name, (c2, sink_info) => {
          if (sink_info != null) {
            var v = sink_info.volume.avg();
            if (v > PulseAudio.Volume.NORM) v = PulseAudio.Volume.NORM;
            var muted = sink_info.mute == 0 ? false : true;
            var volume = (v * 1.0) / PulseAudio.Volume.NORM;

            if (muted) {
              this._img.icon_name = "audio-volume-muted-panel";
            } else {
              if (volume > 0.75) this._img.icon_name = "audio-volume-high-panel";
              else if (volume > 0.33) this._img.icon_name = "audio-volume-medium-panel";
              else this._img.icon_name = "audio-volume-low-panel";
            }
          }
        });
      });
    }
  }
}