namespace GenesisWidgets {
  [GtkTemplate(ui = "/com/expidus/genesis/libwidgets/apps.glade")]
  public class ApplicationIcon : Gtk.Bin {
    public GLib.Icon icon { get; construct; }
    public string label { get; construct; }

    [GtkChild]
    private unowned Gtk.Image icon_;

    [GtkChild]
    private unowned Gtk.Label label_;

    public ApplicationIcon.for_appinfo(GLib.AppInfo appinfo, bool handle_launch = true) {
      Object(icon: appinfo.get_icon(), label: appinfo.get_display_name());

      if (handle_launch) {
        this.clicked.connect(() => {
          try {
            appinfo.launch(null, null);
          } catch (GLib.Error e) {}
        });
      }
    }
    
    construct {
      this.icon_.gicon = this.icon;
      this.label_.label = this.label;
      this.show_all();
    }
    
    [GtkCallback]
    private void do_clicked() {
      this.clicked();
    }

    public signal void clicked();
  }
}