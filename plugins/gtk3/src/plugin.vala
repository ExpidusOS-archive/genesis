namespace GenesisShellGtk3 {
  public sealed class Plugin : GenesisShell.Plugin {
    construct {
      TokyoGtk.init();
    }

    public override void activate(GLib.Cancellable? cancellable = null) throws GLib.Error {
    }

    public override void deactivate(GLib.Cancellable? cancellable = null) throws GLib.Error {
    }
  }

  [CCode(cname = "peas_register_types")]
  internal void register_types(Peas.ObjectModule module) {
    GLib.debug("Registering type");
    module.register_extension_type(typeof (GenesisShell.Plugin), typeof (Plugin));
  }
}
