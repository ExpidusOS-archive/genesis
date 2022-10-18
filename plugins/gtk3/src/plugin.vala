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
      if (this.context.mode != GenesisShell.ContextMode.OPTIONS) {
        this._display.close();
        this._display = null;
      }
    }
  }
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module) {
  var obj_module = module as Peas.ObjectModule;
  assert(obj_module != null);
  obj_module.register_extension_type(typeof (GenesisShell.IPlugin), typeof (GenesisShellGtk3.Plugin));
}
