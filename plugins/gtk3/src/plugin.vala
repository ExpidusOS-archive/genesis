namespace GenesisShellGtk3 {
  public class Plugin : GenesisShell.Plugin {
    internal Gdk.Display display { get; }

    public Plugin(GenesisShell.Context context) {
      Object(context: context);
    }

    construct {
      TokyoGtk.init();
    }

    public override void activate(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this.context.mode != GenesisShell.ContextMode.OPTIONS) {
        this._display = Gdk.Display.get_default();
        assert(this._display != null);

        var style_manager_provider = Tokyo.Provider.get_global().get_style_manager_provider() as TokyoGtk.StyleManagerProvider;
        assert(style_manager_provider != null);

        style_manager_provider.ensure();

        this.container.bind_instance(typeof(GenesisShell.IMonitorProvider), new MonitorProvider(this, cancellable));
      }
    }

    public override void deactivate(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this.context.mode != GenesisShell.ContextMode.OPTIONS) {
        this._display.close();
        this._display = null;
      }
    }
  }
}

#if NOT_LINKABLE
[ModuleInit]
public void peas_register_types(GLib.TypeModule module) {
  var obj_module = module as Peas.ObjectModule;
  assert(obj_module != null);
  obj_module.register_extension_type(typeof(GenesisShell.IPlugin), typeof(GenesisShellGtk3.Plugin));
}
#endif
