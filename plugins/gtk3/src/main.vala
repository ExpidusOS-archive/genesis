[ModuleInit]
public void peas_register_types(GLib.TypeModule module) {
  var obj_module = module as Peas.ObjectModule;
  assert(obj_module != null);
  obj_module.register_extension_type(typeof(GenesisShell.IPlugin), typeof(GenesisShellGtk3.Plugin));
}
