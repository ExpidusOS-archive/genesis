namespace GenesisShell {
  [DBus(name = "com.expidus.genesis.Shell")]
  public interface IContextDBus : GLib.Object {
    public abstract ContextMode mode { get; }
    public abstract string[] plugin_names { owned get; }
  }

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
  }

  [DBus(name = "com.expidus.genesis.ShellError")]
  public errordomain ContextError {
    BAD_PLUGIN
  }

  public sealed class Context : GLib.Object, GLib.AsyncInitable, GLib.Initable {
    private bool _is_init = false;

    internal DBusContext dbus { get; }

    public ContextMode mode { get; construct; default = ContextMode.COMPOSITOR; }
    public Devident.Context devident { get; }

    public GLib.HashTable<string, IPlugin> plugins { get; }
    public Peas.Engine plugin_engine { get; }
    public Peas.ExtensionSet plugin_set { get; }
    public IMonitorProvider monitor_provider { get; }

    public async Context.async(ContextMode mode = ContextMode.COMPOSITOR, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(mode: mode);
      yield this.init_async(GLib.Priority.DEFAULT, cancellable);
    }

    public Context(ContextMode mode = ContextMode.COMPOSITOR, GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object(mode: mode);
      this.init(cancellable);
    }

    construct {
      GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
      GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALDIR);
    }

    private async bool init_async(int io_pri, GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;

      this._dbus = yield new DBusContext.make_async_connection(this, cancellable);
      this.common_init();
      this._is_init = true;
      return true;
    }

    private bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;

      this._dbus = new DBusContext.make_sync_connection(this, cancellable);
      this.common_init();
      this._is_init = true;
      return true;
    }

    private bool common_init() throws GLib.Error {
      if (this._is_init) return true;
      
      this._devident = new Devident.Context();

      this._plugin_engine = new Peas.Engine();
      this._plugin_engine.add_search_path(LIBDIR + "/devident/plugins", DATADIR + "/devident/plugins");

#if TARGET_SYSTEM_WINDOWS
      var prefix = GLib.Win32.get_package_installation_directory_of_module(null);
      this._plugin_engine.add_search_path(GLib.Path.build_filename(prefix, "lib", "devident", "plugins"), GLib.Path.build_filename(prefix, "share", "devident", "plugins"));
#endif

      this._plugin_set = new Peas.ExtensionSet(this.plugin_engine, typeof (IPlugin), "context", this);
      this._monitor_provider = new MonitorProvider(this);

      this._plugin_set.extension_added.connect((info, obj) => {
        this.do_plugin_added.begin(info, obj as IPlugin, null, (obj, res) => {
          try {
            this.do_plugin_added.end(res);
          } catch (GLib.Error e) {
            GLib.error(N_("Failed to add plugin \"%s\": %s:%d: %s"), info.get_name(), e.domain.to_string(), e.code, e.message);
          }
        });
      });

      this._plugin_set.extension_removed.connect((info, obj) => {
        this.do_plugin_removed.begin(info, obj as IPlugin, null, (obj, res) => {
          try {
            this.do_plugin_removed.end(res);
          } catch (GLib.Error e) {
            GLib.error(N_("Failed to add plugin \"%s\": %s:%d: %s"), info.get_name(), e.domain.to_string(), e.code, e.message);
          }
        });
      });
      return true;
    }

    private async bool do_plugin_added(Peas.PluginInfo info, IPlugin? plugin, GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (plugin != null && !this.plugins.contains(info.get_module_name())) {
        GLib.debug(N_("Adding plugin \"%s\" %p"), info.get_name(), plugin);

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
            throw new ContextError.BAD_PLUGIN(N_("Failed to activate plugin \"%s\", class does not extend either GenesisShellAsyncPlugin or GenesisShellPlugin").printf(info.get_name()));
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
      if (plugin != null && !this.plugins.contains(info.get_module_name())) {
        GLib.debug(N_("Removing plugin \"%s\" %p"), info.get_name(), plugin);

        var async_plugin = plugin as AsyncPlugin;
        var sync_plugin = plugin as Plugin;
        assert((async_plugin == null || sync_plugin == null) && !(async_plugin == null && sync_plugin == null));

        try {
          if (async_plugin != null) {
            yield async_plugin.deactivate(cancellable);
          } else if (sync_plugin != null) {
            sync_plugin.deactivate(cancellable);
          } else {
            throw new ContextError.BAD_PLUGIN(N_("Failed to deactivate plugin \"%s\", class does not extend either GenesisShellAsyncPlugin or GenesisShellPlugin").printf(info.get_name()));
          }

          this.plugin_removed(info, plugin);
        } catch (GLib.Error e) {
          this._plugins.remove(info.get_module_name());
          throw e;
        }
        return true;
      }
      return false;
    }

    public signal void plugin_added(Peas.PluginInfo info, IPlugin plugin);
    public signal void plugin_removed(Peas.PluginInfo info, IPlugin plugin);
  }

  internal sealed class DBusContext : GLib.Object, IContextDBus, GLib.Initable {
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
}