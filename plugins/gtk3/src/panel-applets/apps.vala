namespace GenesisShellGtk3 {
  namespace PanelApplets {
    public class Apps : GenesisShellGtk3.PanelApplet {
      public Gtk.Image icon { get; }

      public Apps(GenesisShell.Monitor monitor, string id) {
        Object(monitor: monitor, id: id);
      }

      construct {
        this.get_style_context().add_class("genesis-shell-panel-applet-apps");

        this._icon = new Icon.for_monitor("view-app-grid", this.monitor, PanelWidget.APPLET_ICON_UNIT_SIZE);
        this._icon.halign = Gtk.Align.CENTER;
        this._icon.valign = Gtk.Align.CENTER;
        this.add(this._icon);

        this.halign = Gtk.Align.CENTER;
        this.valign = Gtk.Align.CENTER;
      }
    }
  }
}
