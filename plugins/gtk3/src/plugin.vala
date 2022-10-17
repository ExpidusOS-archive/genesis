namespace GenesisShellGtk3 {
  public sealed class Plugin : GenesisShell.Plugin {
    internal Gdk.Display display { get; }

    construct {
      TokyoGtk.init();
    }

    public override void activate(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this.context.mode != GenesisShell.ContextMode.OPTIONS) {
        this._display = Gdk.Display.get_default();
        assert(this._display != null);

        this.container.bind_instance(typeof (GenesisShell.IMonitorProvider), new MonitorProvider(this, cancellable));
      }
    }

    public override void deactivate(GLib.Cancellable? cancellable = null) throws GLib.Error {
      this._display.close();
      this._display = null;
    }
  }

  [CCode(cname = "peas_register_types")]
  public void register_types(Peas.ObjectModule module) {
    string[] types = {
      typeof (MonitorProvider).name(),
      typeof (Monitor).name()
    };
    
    GLib.debug(N_("Registering types: %s").printf(string.joinv(", ", types)));
    module.register_extension_type(typeof (GenesisShell.IPlugin), typeof (GenesisShellGtk3.Plugin));
  }
}
