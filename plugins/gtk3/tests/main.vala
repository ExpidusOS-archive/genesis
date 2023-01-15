public static int main(string[] args) {
  Gtk.test_init(ref args);
  TokyoGtk.init();

  GLib.Test.add_func("/mode/big-picture", () => {
    try {
      var context = new GenesisShell.Context(GenesisShell.ContextMode.BIG_PICTURE);
      new GenesisShellGtk3.Plugin(context).activate();
    } catch (GLib.Error e) {
      GLib.error("%s:%d: %s", e.domain.to_string(), e.code, e.message);
    }
  });

  return GLib.Test.run();
}
