namespace GenesisShellGtk3 {
  namespace PanelApplets {
    public class Keyboard : GenesisShellGtk3.PanelApplet {
      public IBus.Bus ibus { get; }
      public Gtk.Button button { get; }

      public Keyboard(GenesisShell.Monitor monitor, string id) {
        Object(monitor: monitor, id: id);
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-keyboard");

        // FIXME: image should be centered but it is not
        this._button = new Gtk.Button();
        this._button.image = new Icon.for_monitor("keyboard-layout", this.monitor, PanelWidget.UNIT_SIZE);
        this._button.always_show_image = true;
        this._button.image_position = Gtk.PositionType.TOP;
        this._button.halign = Gtk.Align.CENTER;
        this._button.valign = Gtk.Align.CENTER;
        this.add(this._button);

        this.halign = Gtk.Align.CENTER;
        this.valign = Gtk.Align.CENTER;

        this._ibus = new IBus.Bus();
        this._ibus.global_engine_changed.connect(() => this.update());
        this._ibus.connected.connect(() => this.update());
      }

      private void update() {
        var desc = this.ibus.get_global_engine();
        stdout.printf("%s\n", desc.get_language());
      }

      private int get_size() {
        var value = GenesisShell.Math.scale(this.monitor.dpi, PanelWidget.UNIT_SIZE);
        var monitor = this.monitor as Monitor;
        if (monitor != null) {
          var panel = monitor.panel_widget;
          if (panel != null) {
            var style_ctx = panel.get_style_context();
            var padding = style_ctx.get_padding(style_ctx.get_state());
            value += padding.top + padding.bottom;
          }
        }
        return value;
      }

      public override void size_allocate(Gtk.Allocation alloc) {
        alloc.y = ((this.get_size() / 2) - alloc.y) / 2;
        alloc.width = this.get_size();
        alloc.height = this.get_size();
        base.size_allocate(alloc);
      }

      public override void get_preferred_height(out int min_height, out int nat_height) {
        min_height = nat_height = this.get_size();
      }

      public override void get_preferred_width(out int min_width, out int nat_width) {
        min_width = nat_width = this.get_size();
      }
    }
  }
}
