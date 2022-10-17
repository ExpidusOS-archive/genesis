namespace GenesisShellGtk3 {
  public sealed class Plugin : GenesisShell.Plugin {
    construct {
      TokyoGtk.init();
    }

    public override void activate(GLib.Cancellable? cancellable = null) throws GLib.Error {
      GLib.debug("Plugin is active");
    }

    public override void deactivate(GLib.Cancellable? cancellable = null) throws GLib.Error {
    }
  }

  [CCode(cname = "peas_register_types")]
  internal void register_types(Peas.ObjectModule module) {
    module.register_extension_type(typeof (GenesisShell.IPlugin), typeof (GenesisShellGtk3.Plugin));
  }
}
