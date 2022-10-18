private static bool arg_version = false;
private static string? arg_shell_mode = null;

private const GLib.OptionEntry[] options = {
  { "version", '\0', GLib.OptionFlags.NONE, GLib.OptionArg.NONE, ref arg_version, N_("Print version string"), null },
  { "mode", 'm', GLib.OptionFlags.NONE, GLib.OptionArg.STRING, ref arg_shell_mode, N_("Mode to run in"), "MODE" },
  { null }
};

public static int main(string[] args) {
  GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
  GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALDIR);

  try {
    var opt_ctx = new GLib.OptionContext(N_("- Genesis Shell - The next-generation desktop and mobile compositor and window manager."));
    var ctx = new GenesisShell.Context(GenesisShell.ContextMode.OPTIONS);

    opt_ctx.set_help_enabled(true);
    opt_ctx.add_main_entries(options, null);

    foreach (var plugin_id in ctx.plugins.get_keys()) {
      var opt_group = ctx.get_option_group_for_plugin(plugin_id);
      if (opt_group == null) continue;
      opt_ctx.add_group(opt_group);
    }

    opt_ctx.parse(ref args);

    if (arg_version) {
      stdout.printf(N_("Genesis Shell v%s\n"), GenesisShell.VERSION);
      stdout.printf("\n");

      foreach (var plugin_id in ctx.plugins.get_keys()) {
        var plugin_info = ctx.plugin_engine.get_plugin_info(plugin_id);
        if (plugin_info == null) continue;

        var version = plugin_info.get_version();
        stdout.printf(N_("Plugin \"%s\" (%s, %s)"), plugin_info.get_module_name(), plugin_id, version == null ? N_("no version") : version);
      }
      return 0;
    }

    var mode = GenesisShell.ContextMode.COMPOSITOR;
    if (arg_shell_mode != null) {
      if (!GenesisShell.ContextMode.try_parse_nick(arg_shell_mode, out mode)) {
        stderr.printf(N_("%s: invalid shell mode \"%s\"\n"), args[0], arg_shell_mode);
        return 1;
      }
    }

    if (mode == GenesisShell.ContextMode.OPTIONS) {
      stderr.printf(N_("%s: cannot start the shell in options mode\n"), args[0]);
      return 1;
    }

    var loop = new GLib.MainLoop();
    ctx.shutdown.connect(() => loop.quit());
    ctx.reload_async.begin(mode, null, (obj, res) => {
      try {
        ctx.reload_async.end(res);
      } catch (GLib.Error e) {
        stderr.printf(N_("%s: failed to start the shell: %s:%d: %s\n"), args[0], e.domain.to_string(), e.code, e.message);
        loop.quit();
      }
    });
    loop.run();
    return 0;
  } catch (GLib.Error e) {
    stderr.printf(N_("%s: failed to handle arguments: %s:%d: %s\n"), args[0], e.domain.to_string(), e.code, e.message);
    return 1;
  }
}
