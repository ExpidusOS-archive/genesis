namespace GenesisShellGtk3 {
  namespace PanelApplets {
    public class Keyboard : GenesisShellGtk3.PanelApplet {
      public IBus.Bus ibus { get; }
      public Gtk.Image icon { get; }

      public Keyboard(GenesisShell.Monitor monitor, string id) {
        Object(monitor: monitor, id: id);
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-keyboard");

        // FIXME: image should be centered but it is not
        this._icon = new Icon.for_monitor("keyboard-layout", this.monitor, PanelWidget.UNIT_SIZE);
        this._icon.halign = Gtk.Align.CENTER;
        this._icon.valign = Gtk.Align.CENTER;
        this.add(this._icon);

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
    }
  }
}
