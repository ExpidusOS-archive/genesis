namespace GenesisShell {
#if HAS_DBUS
  [DBus(name = "com.expidus.genesis.Shell")]
  public interface IContextDBus : GLib.Object {
    public abstract ContextMode mode { get; }
    public abstract string[] plugin_names { owned get; }

    public signal void shutdown();
  }
#endif

  [DBus(name = "com.expidus.genesis.ShellMode")]
  public enum ContextMode {
    /**
     * Compositor mode
     *
     * This indicates the context is running as a compositor and window manager.
     * This is essentially the full shell.
     */
    COMPOSITOR = 0,

    /**
     * Big picture
     *
     * This indicates the context is running in a state similar to Steam Big Picture
     * or Kodi. This is where the shell is running in a semi-embedded state and
     * so many or all features will not be available.
     */
    BIG_PICTURE,

    /**
     * Gadgets
     *
     * This indicates the context is running to render only the GUI layer.
     * This means it doesn't handle any window management or compositing.
     * If there is a compositor running already, then this is used.
     */
    GADGETS,

    /**
     * Options
     *
     * This only used for loading the context enough for parsing
     * command line arguments.
     */
    OPTIONS;

    public static bool try_parse_name(string name, out ContextMode result = null) {
      var enumc = (GLib.EnumClass)(typeof (ContextMode).class_ref());
      unowned var eval = enumc.get_value_by_name(name);

      if (eval == null) {
        result = ContextMode.COMPOSITOR;
        return false;
      }

      result = (ContextMode)eval.value;
      return true;
    }

    public static bool try_parse_nick(string name, out ContextMode result = null) {
      var enumc = (GLib.EnumClass)(typeof (ContextMode).class_ref());
      unowned var eval = enumc.get_value_by_nick(name);
      return_val_if_fail(eval != null, false);

      if (eval == null) {
        result = ContextMode.COMPOSITOR;
        return false;
      }

      result = (ContextMode)eval.value;
      return true;
    }

    public string to_nick() {
      var enumc = (GLib.EnumClass)(typeof (ContextMode).class_ref());
      var eval  = enumc.get_value(this);
      return_val_if_fail(eval != null, null);
      return eval.value_nick;
    }
  }

  [DBus(name = "com.expidus.genesis.ShellError")]
  public errordomain ContextError {
    BAD_PLUGIN,
    BAD_LAUNCH,
    INVALID_MODE
  }

  public sealed class Context : GLib.Object, GLib.AsyncInitable, GLib.Initable {
    private bool _is_init = false;
    private IMonitorProvider? _monitor_provider;
    private IUIProvider? _ui_provider;
    private IWindowProvider? _window_provider;
    private IWorkspaceProvider? _workspace_provider;
    private bool _is_shutting_down = false;
    private bool _is_reloading = false;

#if HAS_DBUS
    private uint _dbus_name_id;
    internal DBusContext dbus { get; }
#endif

    public GLib.Settings settings { get; }

    public ContextMode mode { get; construct; default = ContextMode.COMPOSITOR; }
    public Devident.Context devident { get; }
    public Vdi.Container container { get; }

    public GLib.HashTable<string, IPlugin> plugins { get; }
    public Peas.Engine plugin_engine { get; }
    public Peas.ExtensionSet plugin_set { get; }
    
    public IMonitorProvider monitor_provider {
      get {
        if (this._monitor_provider == null) {
          var provider = this.container.get(typeof (IMonitorProvider)) as IMonitorProvider;
          if (provider == null) provider = new MonitorProvider(this);

          this._monitor_provider = provider;
        }
        return this._monitor_provider;
      }
    }
    
    public IWindowProvider window_provider {
      get {
        if (this._window_provider == null) {
          var provider = this.container.get(typeof (IWindowProvider)) as IWindowProvider;
          if (provider == null) provider = new WindowProvider(this);

          this._window_provider = provider;
        }
        return this._window_provider;
      }
    }

    public IWorkspaceProvider workspace_provider {
      get {
        if (this._workspace_provider == null) {
          var provider = this.container.get(typeof (IWorkspaceProvider)) as IWorkspaceProvider;
          if (provider == null) provider = new WorkspaceProvider(this);

          this._workspace_provider = provider;
        }
        return this._workspace_provider;
      }
    }

    public async Context.async(ContextMode mode = ContextMode.COMPOSITOR, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(mode: mode);
      yield this.init_async(GLib.Priority.DEFAULT, cancellable);
    }

    public Context(ContextMode mode = ContextMode.COMPOSITOR, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(mode: mode);
      this.init(cancellable);
    }

    ~Context() {
#if HAS_DBUS
      if (this.mode != ContextMode.OPTIONS) {
        if (this._dbus_name_id > 0) {
          GLib.Bus.unown_name(this._dbus_name_id);
          this._dbus_name_id = 0;
        }
      }
#endif
    }

    construct {
      GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
      GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALDIR);

      this._plugins = new GLib.HashTable<string, IPlugin>(GLib.str_hash, GLib.str_equal);
      this._settings = new GLib.Settings("com.expidus.genesis");
    }

    public GLib.OptionGroup? get_option_group_for_plugin(string plugin_name) {
      var plugin = this.plugins.get(plugin_name);
      if (plugin == null) return null;

      var plugin_info = this.plugin_engine.get_plugin_info(plugin_name);
      var group = new GLib.OptionGroup(plugin_name, _("Plugin \"%s\" Options").printf(plugin_info.get_name()), _("Show all options for the \"%s\" plugin").printf(plugin_info.get_name()));
      group.add_entries(plugin.get_options());
      return group;
    }

    /**
     * Clears the internal cached instances of the providers.
     *
     * This sets the internal provider properties which causes Vdi
     * to fetch the providers and store them again. This is mainly
     * used when a plugin wants to override the global providers.
     *
     * This method should not be called often as it may cause
     * a slight slowdown with grabbing the providers.
     * 
     * If you override the global providers, be sure to
     * unbind them from Vdi and call this method when
     * your plugin unloads. If you do not call this method and you
     * override the global providers then it will cause side effects.
     */
    public void invalidate_providers() {
      this._monitor_provider = null;
      this._ui_provider = null;
      this._window_provider = null;
      this._workspace_provider = null;
    }

    /**
     * Reloads the shell and upgrades the context mode.
     *
     * This only works going from the options mode and so can only be called once.
     */
    public bool reload(ContextMode mode, GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (!this._is_init) throw new ContextError.BAD_LAUNCH(_("Not initialized"));
      if (this.mode == mode) throw new ContextError.INVALID_MODE(_("Target mode and current mode both match"));
      if (this.mode != ContextMode.OPTIONS) throw new ContextError.INVALID_MODE(_("Cannot upgrade from a %s to %s mode").printf(this.mode.to_nick(), mode.to_nick()));

      GLib.debug(_("Reloading Genesis Shell from mode %s to mode %s").printf(this.mode.to_nick(), mode.to_nick()));

      this._is_init = false;
      foreach (var info in this.plugin_engine.get_plugin_list()) {
        var obj = this._plugins.get(info.get_module_name());
        this.do_plugin_removed.begin(info, obj, cancellable, (obj, res) => {
          try {
            this.do_plugin_removed.end(res);
          } catch (GLib.Error e) {
            GLib.error(_("Failed to remove plugin \"%s\": %s:%d: %s"), info.get_name(), e.domain.to_string(), e.code, e.message);
          }
        });
      }

      this._mode = mode;
      this._is_reloading = true;
      try {
        return this.init(cancellable);
      } finally {
        this._is_reloading = false;
      }
    }

    /**
     * Reloads the shell and upgrades the context mode.
     *
     * This only works going from the options mode and so can only be called once.
     */
    public async bool reload_async(ContextMode mode, GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (!this._is_init) throw new ContextError.BAD_LAUNCH(_("Not initialized"));
      if (this.mode == mode) throw new ContextError.INVALID_MODE(_("Target mode and current mode both match"));
      if (this.mode != ContextMode.OPTIONS) throw new ContextError.INVALID_MODE(_("Cannot upgrade from a %s to %s mode").printf(this.mode.to_nick(), mode.to_nick()));

      GLib.debug(_("Reloading Genesis Shell from mode %s to mode %s").printf(this.mode.to_nick(), mode.to_nick()));

      this._is_init = false;
      foreach (var info in this.plugin_engine.get_plugin_list()) {
        var obj = this._plugins.get(info.get_module_name());
        yield this.do_plugin_removed(info, obj, cancellable);
      }

      this._mode = mode;
      this._is_reloading = true;
      try {
        return yield this.init_async(GLib.Priority.DEFAULT, cancellable);
      } finally {
        this._is_reloading = false;
      }
    }

    private async bool init_async(int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;

#if HAS_DBUS
      if (this.mode != ContextMode.OPTIONS) {
        this._dbus = yield new DBusContext.make_async_connection(this, cancellable);
      }
#endif
      this.common_init();
      if (this._is_reloading) {
        foreach (var info in this.plugin_engine.get_plugin_list()) {
          var obj = this.plugin_set.get_extension(info) as IPlugin;
          yield this.do_plugin_added(info, obj, cancellable);
        }
      }
      this._is_init = true;
      return true;
    }

    private bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;

#if HAS_DBUS
      if (this.mode != ContextMode.OPTIONS) {
        this._dbus = new DBusContext.make_sync_connection(this, cancellable);
      }
#endif
      this.common_init();
      if (this._is_reloading) {
        foreach (var info in this.plugin_engine.get_plugin_list()) {
          var obj = this.plugin_set.get_extension(info) as IPlugin;
          this.do_plugin_added.begin(info, obj, cancellable, (obj, res) => {
            try {
              this.do_plugin_added.end(res);
            } catch (GLib.Error e) {
              GLib.error(_("Failed to add plugin \"%s\": %s:%d: %s"), info.get_name(), e.domain.to_string(), e.code, e.message);
            }
          });
        }
      }
      this._is_init = true;
      return true;
    }

    private bool common_init() throws GLib.Error {
      if (this._is_init) return true;

      if (!this._is_reloading) {
        this._devident = Devident.Context.get_global();
        this._container = new Vdi.Container();

        this._container.bind_factory(typeof (IMonitorProvider), () => new MonitorProvider(this));
        this._container.bind_factory(typeof (IUIProvider), () => new UIProvider(this));
        this._container.bind_factory(typeof (IWindowProvider), () => new WindowProvider(this));
        this._container.bind_factory(typeof (IWorkspaceProvider), () => new WorkspaceProvider(this));

        this._plugin_engine = new Peas.Engine.with_nonglobal_loaders();
        this._plugin_engine.add_search_path(LIBDIR + "/genesis-shell/plugins", DATADIR + "/genesis-shell/plugins");

        var plugin_paths_env = GLib.Environment.get_variable("GENESIS_SHELL_PLUGINS_PATH");
        if (plugin_paths_env != null) {
          var entries = plugin_paths_env.split(":");
          if ((entries.length % 2) != 0) throw new ContextError.BAD_LAUNCH(_("Plugins path is not a multiple of 2"));

          for (var i = 0; i < entries.length; i += 2) {
            var lib = entries[i];
            var data = entries[i + 1];
            GLib.debug("Adding plugins path %d, lib: %s, data: %s", (int)(i / 2), lib, data);
            this._plugin_engine.add_search_path(lib, data);
          }
        }

#if TARGET_SYSTEM_WINDOWS
        var prefix = GLib.Win32.get_package_installation_directory_of_module(null);
        this._plugin_engine.add_search_path(GLib.Path.build_filename(prefix, "lib", "devident", "plugins"), GLib.Path.build_filename(prefix, "share", "devident", "plugins"));
#endif

        this._plugin_set = new Peas.ExtensionSet(this._plugin_engine, typeof (IPlugin), "context", this);

        this._plugin_set.extension_added.connect((info, obj) => {
          this.do_plugin_added.begin(info, obj as IPlugin, null, (obj, res) => {
            try {
              this.do_plugin_added.end(res);
            } catch (GLib.Error e) {
              GLib.error(_("Failed to add plugin \"%s\": %s:%d: %s"), info.get_name(), e.domain.to_string(), e.code, e.message);
            }
          });
        });

        this._plugin_set.extension_removed.connect((info, obj) => {
          this.do_plugin_removed.begin(info, obj as IPlugin, null, (obj, res) => {
            try {
              this.do_plugin_removed.end(res);
            } catch (GLib.Error e) {
              GLib.error(_("Failed to remove plugin \"%s\": %s:%d: %s"), info.get_name(), e.domain.to_string(), e.code, e.message);
            }
          });
        });

        this.monitor_provider.added.connect((monitor) => {
          GLib.debug(_("Monitor \"%s\" has been added").printf(monitor.id));
          monitor.load_settings();
        });
        this._monitor_provider.removed.connect((monitor) => GLib.debug(_("Monitor \"%s\" has been removed").printf(monitor.id)));
      }

      GLib.debug(_("Genesis Shell context %p is running in mode %s"), this, this.mode.to_nick());

      this.plugin_engine.rescan_plugins();

      if (!this._is_reloading) {
        foreach (var info in this.plugin_engine.get_plugin_list()) {
          GLib.debug(_("Plugin %s found in engine, trying to load"), info.get_module_name());
          if (!this.plugin_engine.try_load_plugin(info)) GLib.warning(_("Plugin %s failed to load"), info.get_module_name());
        }
      }

      switch (this.mode) {
        case ContextMode.COMPOSITOR:
#if ! HAS_DBUS
          throw new ContextError.BAD_LAUNCH(_("Compositor mode requires dbus support to be enabled"));
#else
          this._dbus_name_id = GLib.Bus.own_name_on_connection(this.dbus.connection, "com.expidus.genesis.Compositor", GLib.BusNameOwnerFlags.DO_NOT_QUEUE);
          break;
#endif
        case ContextMode.GADGETS:
#if ! HAS_DBUS
          throw new ContextError.BAD_LAUNCH(_("Gadgets mode requires dbus support to be enabled"));
#else
          this._dbus_name_id = GLib.Bus.own_name_on_connection(this.dbus.connection, "com.expidus.genesis.Gadgets", GLib.BusNameOwnerFlags.DO_NOT_QUEUE);
          break;
        case ContextMode.BIG_PICTURE:
          this._dbus_name_id = GLib.Bus.own_name_on_connection(this.dbus.connection, "com.expidus.genesis.BigPicture", GLib.BusNameOwnerFlags.DO_NOT_QUEUE);
          break;
#endif
        default:
          break;
      }
      return true;
    }

    private async bool do_plugin_added(Peas.PluginInfo info, IPlugin? plugin, GLib.Cancellable? cancellable = null) throws GLib.Error {
      GLib.debug(_("Discovered plugin %s"), info.get_module_name());

      if (info.get_module_name() in this.settings.get_strv("plugin-blacklist")) {
        GLib.debug(_("Plugin \"%s\" is disabled"), info.get_module_name());
        return true;
      }

      var context_modes = info.get_external_data("ContextModes");
      if (context_modes != null) {
        ContextMode[] wants_context_modes = {};
        foreach (var cmode in context_modes.split(";")) {
          if (cmode.length == 0) break;

          var rmode = ContextMode.COMPOSITOR;
          if (!ContextMode.try_parse_nick(cmode, out rmode)) continue;

          wants_context_modes += rmode;
        }

        if (!(this.mode in wants_context_modes)) {
          GLib.debug(_("Skipping plugin \"%s\", not in correct plugin mode"), info.get_module_name());
          return true;
        }
      }

      var conflicts = info.get_external_data("Conflicts");
      if (conflicts != null) {
        foreach (var conf in conflicts.split(";")) {
          if (conf.length == 0) break;
          if (conf in this.plugin_engine.loaded_plugins) {
            GLib.debug(_("Skipping plugin \"%s\", avoiding confliction with \"%s\""), info.get_module_name(), conf);
            return true;
          }
        }
      }

      if (plugin != null && !this.plugins.contains(info.get_module_name())) {
        GLib.debug(_("Adding plugin \"%s\" %p"), info.get_module_name(), plugin);

        var async_plugin = plugin as AsyncPlugin;
        var sync_plugin = plugin as Plugin;
        assert((async_plugin == null || sync_plugin == null) && !(async_plugin == null && sync_plugin == null));

        this._plugins.set(info.get_module_name(), plugin);

        try {
          if (async_plugin != null) {
            yield async_plugin.activate(cancellable);
          } else if (sync_plugin != null) {
            sync_plugin.activate(cancellable);
          } else {
            throw new ContextError.BAD_PLUGIN(_("Failed to activate plugin \"%s\", class does not extend either GenesisShellAsyncPlugin or GenesisShellPlugin").printf(info.get_module_name()));
          }

          this.plugin_added(info, plugin);
        } catch (GLib.Error e) {
          this._plugins.remove(info.get_module_name());
          throw e;
        }
        return true;
      }
      return false;
    }

    private async bool do_plugin_removed(Peas.PluginInfo info, IPlugin? plugin, GLib.Cancellable? cancellable = null) throws GLib.Error {
      GLib.debug(_("Discovered plugin %s"), info.get_module_name());
      if (plugin != null && this.plugins.contains(info.get_module_name())) {
        GLib.debug(_("Removing plugin \"%s\" %p"), info.get_name(), plugin);

        var async_plugin = plugin as AsyncPlugin;
        var sync_plugin = plugin as Plugin;
        assert((async_plugin == null || sync_plugin == null) && !(async_plugin == null && sync_plugin == null));

        this._plugins.remove(info.get_module_name());

        try {
          if (async_plugin != null) {
            yield async_plugin.deactivate(cancellable);
          } else if (sync_plugin != null) {
            sync_plugin.deactivate(cancellable);
          } else {
            throw new ContextError.BAD_PLUGIN(_("Failed to deactivate plugin \"%s\", class does not extend either GenesisShellAsyncPlugin or GenesisShellPlugin").printf(info.get_name()));
          }

          this.plugin_removed(info, plugin);
        } catch (GLib.Error e) {
          this._plugins.set(info.get_module_name(), plugin);
          throw e;
        }
        return true;
      } else {
        if (!this.plugins.contains(info.get_module_name())) GLib.warning(_("Plugin \"%s\" is already added").printf(info.get_name()));
      }
      return false;
    }

    public signal void plugin_added(Peas.PluginInfo info, IPlugin plugin);
    public signal void plugin_removed(Peas.PluginInfo info, IPlugin plugin);

    public virtual signal void shutdown() {
      if (this._is_shutting_down) {
        return;
      }

      this._is_shutting_down = true;

      foreach (var info in this.plugin_engine.get_plugin_list()) {
        GLib.debug(_("Plugin %s found in engine, trying to unload"), info.get_module_name());
        if (!this.plugin_engine.try_unload_plugin(info)) GLib.warning(_("Plugin %s failed to unload"), info.get_module_name());
      }
    }
  }

#if HAS_DBUS
  private sealed class DBusContext : GLib.Object, IContextDBus, GLib.Initable {
    private bool _is_init = false;
    private uint _obj_id;

    public GLib.DBusConnection connection { get; construct; }
    public Context context { get; construct; }

    public ContextMode mode {
      get {
        return this.context.mode;
      }
    }

    public string[] plugin_names {
      owned get {
        return this.context.plugins.get_keys_as_array();
      }
    }

    internal DBusContext(Context context, GLib.DBusConnection connection, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(context: context, connection: connection);
      this.init(cancellable);
    }

    internal async DBusContext.make_async_connection(Context context, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(context: context, connection: yield GLib.Bus.get(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    internal DBusContext.make_sync_connection(Context context, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(context: context, connection: GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    construct {
      this.context.shutdown.connect(() => this.shutdown());
    }

    ~DBusContext() {
      if (this._obj_id > 0) {
        if (this.connection.unregister_object(this._obj_id)) this._obj_id = 0;
      }
    }

    private bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;

      this._obj_id = this.connection.register_object("/com/expidus/genesis/Shell", (IContextDBus)this);
      this._is_init = true;
      return true;
    }
  }
#endif
}
