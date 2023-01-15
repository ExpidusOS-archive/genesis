namespace GenesisShellGtk3 {
  namespace PanelApplets {
    public class Clock : GenesisShellGtk3.PanelApplet {
      private uint _timeout_id;
      private ulong _clock_format_id;

      public Gtk.Label label { get; }

      public Clock(GenesisShell.Monitor monitor, string id) {
        Object(monitor: monitor, id: id);
      }

      ~Clock() {
        if (this._timeout_id > 0) {
          GLib.Source.remove(this._timeout_id);
          this._timeout_id = 0;
        }

        if (this._clock_format_id > 0) {
          this.context.settings.disconnect(this._clock_format_id);
          this._clock_format_id = 0;
        }
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-clock");

        this._label = new Gtk.Label("00:00 MM");
        this.add(this.label);
        this.update();

        this._timeout_id = GLib.Timeout.add_seconds(1, () => {
          this.update();
          return true;
        });

        this._clock_format_id = this.context.settings.notify["clock-format"].connect(() => this.update());
      }

      private void update() {
        var dt   = new GLib.DateTime.now();
        var time = dt.format(this.context.settings.get_string("clock-format"));
        this._label.label = time;
      }

      public override void size_allocate(Gtk.Allocation alloc) {
        base.size_allocate(alloc);
        if (this._label != null) this._label.size_allocate(alloc);
      }

      public override void get_preferred_height(out int min_height, out int nat_height) {
        if (this._label != null) this._label.get_preferred_height(out min_height, out nat_height);
        else base.get_preferred_height(out min_height, out nat_height);
      }

      public override void get_preferred_width(out int min_width, out int nat_width) {
        if (this._label != null) this._label.get_preferred_width(out min_width, out nat_width);
        else base.get_preferred_width(out min_width, out nat_width);
      }
    }
  }
}
