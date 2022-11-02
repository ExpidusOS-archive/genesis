namespace GenesisShell {
  [DBus(name = "com.expidus.genesis.Shell")]
  public interface IContextDBus : GLib.Object {
    public abstract ContextMode mode { get; }
    public abstract string[] plugin_names { owned get; }

    public signal void shutdown();
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

    internal DBusContext(Context context, GLib.DBusConnection connection, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(context: context, connection: connection);
      this.init(cancellable);
    }

    internal async DBusContext.make_async_connection(Context context, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(context: context, connection: yield GLib.Bus.get(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    internal DBusContext.make_sync_connection(Context context, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(context: context, connection: GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable));
      this.init(cancellable);
    }

    construct {
      this.context.shutdown.connect(() => this.shutdown());
    }

    ~DBusContext() {
      if (this._obj_id > 0) {
        if (this.connection.unregister_object(this._obj_id)) {
          this._obj_id = 0;
        }
      }
    }

    private bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this._is_init) {
        return true;
      }

      this._obj_id  = this.connection.register_object("/com/expidus/genesis/Shell", (IContextDBus)this);
      this._is_init = true;
      return true;
    }
  }
}
