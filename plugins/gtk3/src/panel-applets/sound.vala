namespace GenesisShellGtk3 {
  namespace PanelApplets {
    public class SoundDevice : GenesisShellGtk3.PanelApplet {
      private ulong _muted_id;
      private ulong _volume_id;

      public Gtk.Adjustment adjustment { get; }
      public Gtk.Button button { get; }
      public Gvc.MixerStream mixer { get; construct; }

      public unowned Gvc.MixerUIDevice device {
        get {
          return this.context.mixer_control.lookup_device_from_stream(this.mixer);
        }
      }

      public string icon_name_format {
        get {
          if (this.mixer is Gvc.MixerSource) return "audio-input-microphone-%s";
          if (this.mixer is Gvc.MixerSourceOutput) return "audio-input-microphone-%s";

          if (this.mixer is Gvc.MixerSink) return "audio-volume-%s";
          if (this.mixer is Gvc.MixerSinkInput) return "audio-volume-%s";
          return "audio-card";
        }
      }

      public double volume {
        get {
          return this.adjustment.value / this.adjustment.upper;
        }
        set {
          this.adjustment.value = value * this.adjustment.upper;
        }
      }

      public SoundDevice(GenesisShell.Monitor monitor, Gvc.MixerStream mixer) {
        Object(monitor: monitor, mixer: mixer);
      }

      ~SoundDevice() {
        if (this._muted_id > 0) {
          this.mixer.disconnect(this._muted_id);
          this._muted_id = 0;
        }

        if (this._volume_id > 0) {
          this.mixer.disconnect(this._volume_id);
          this._volume_id = 0;
        }
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-sound-device");

        // FIXME: image should be centered but it is not
        this._button = new Gtk.Button();
        this._button.image = new Icon.for_monitor(this.icon_name_format.printf("high"), this.monitor, PanelWidget.UNIT_SIZE);
        this._button.always_show_image = true;
        this._button.image_position = Gtk.PositionType.TOP;
        this._button.halign = Gtk.Align.CENTER;
        this._button.valign = Gtk.Align.CENTER;
        this.add(this._button);

        this._adjustment = new Gtk.Adjustment(this.mixer.volume * 1.0, 0.0, this.context.mixer_control.get_vol_max_norm(), this.context.mixer_control.get_vol_max_norm() / 100.0, this.context.mixer_control.get_vol_max_norm() / 10.0, 0.0);
        this._adjustment.value_changed.connect(() => {
          if (this.adjustment.value != (this.mixer.volume * 1.0)) this.mixer.set_volume((uint32)this.adjustment.value);
          this.update();
        });

        this._muted_id = this.mixer.notify["is-muted"].connect(() => this.update());
        this._volume_id = this.mixer.notify["volume"].connect(() => {
          this.adjustment.value = this.mixer.volume * 1.0;
          this.update();
        });

        this.halign = Gtk.Align.CENTER;
        this.valign = Gtk.Align.CENTER;

        GLib.debug(_("Found audio mixer %lu"), this.mixer.id);
        this.update();
      }

      private void update() {
        if (this.mixer.is_muted) {
          this.tooltip_text = _("%s (Muted)").printf(this.device.description);
          ((Gtk.Image)this._button.image).icon_name = this.icon_name_format.printf("muted");
        } else {
          this.tooltip_text = _("%s (%0.2f%%)").printf(this.device.description, this.volume * 100.0);

          if (this.volume >= 0.7) ((Gtk.Image)this._button.image).icon_name = this.icon_name_format.printf("high");
          else if (this.volume >= 0.4) ((Gtk.Image)this._button.image).icon_name = this.icon_name_format.printf("medium");
          else ((Gtk.Image)this._button.image).icon_name = this.icon_name_format.printf("low");
        }
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

      public override void size_allocate(Gtk.Allocation alloc) {
        alloc.y = (this.get_size() / 4) - alloc.y;
        alloc.width = this.get_size();
        alloc.height = this.get_size();
        base.size_allocate(alloc);
      }

      public override void get_preferred_width(out int min_width, out int nat_width) {
        min_width = nat_width = this.get_size();
      }

      public override void get_preferred_height(out int min_height, out int nat_height) {
        min_height = nat_height = this.get_size();
      }
    }

    public class Sound : GenesisShellGtk3.PanelApplet {
      private Gtk.Box _box;
      private GLib.HashTable<ulong, SoundDevice> _devices;
      private ulong _sink_changed_id;
      private ulong _source_changed_id;

      public Sound(GenesisShell.Monitor monitor, string id) {
        Object(monitor: monitor, id: id);
      }

      ~Sound() {
        if (this._sink_changed_id > 0) {
          this.context.mixer_control.disconnect(this._sink_changed_id);
          this._sink_changed_id = 0;
        }

        if (this._source_changed_id > 0) {
          this.context.mixer_control.disconnect(this._source_changed_id);
          this._source_changed_id = 0;
        }
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-sound");

        this._devices = new GLib.HashTable <ulong, SoundDevice>((a) => GLib.str_hash(a.to_string()), (a, b) => a == b);
        this._box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        this._box.halign = Gtk.Align.CENTER;
        this._box.valign = Gtk.Align.CENTER;
        this.add(this._box);

        this.halign = Gtk.Align.CENTER;
        this.valign = Gtk.Align.CENTER;

        if (this.context.mixer_control.get_state() == Gvc.MixerControlState.READY) {
          this.context.mixer_control.default_sink_changed.connect(() => this.default_changed());
          this.context.mixer_control.default_source_changed.connect(() => this.default_changed());

          this.init();
        } else {
          GLib.warning(_("Failed to open audio connection: %s"), this.context.mixer_control.get_state().to_string());
        }
      }

      private void init() {
        var sink = this.context.mixer_control.get_default_sink();
        if (sink != null) this.add_mixer(sink);

        var source = this.context.mixer_control.get_default_source();
        if (source != null) this.add_mixer(source);
      }

      private void default_changed() {
        foreach (var dev in this._devices.get_values()) this.remove_mixer(dev.mixer);
        this.init();
      }

      private void add_mixer(Gvc.MixerStream mixer) {
        if (!this._devices.contains(mixer.id)) {
          var device = new SoundDevice(this.monitor, mixer);
          this._box.add(device);
          this._devices.set(mixer.id, device);
          device.show_all();
        }
      }

      private void remove_mixer(Gvc.MixerStream mixer) {
        if (this._devices.contains(mixer.id)) {
          var device = this._devices.get(mixer.id);
          this._devices.remove(mixer.id);
          this._box.remove(device);
        }
      }
    }
  }
}
