namespace GenesisShell {
  [DBus(name = "com.expidus.genesis.Shell")]
  public interface IContextDBus : GLib.Object {
    public abstract ContextMode mode { get; }
    public abstract string[] plugin_names { owned get; }

    public abstract void invalidate_providers() throws GLib.DBusError, GLib.IOError;
    public signal void shutdown();
  }

  public class ClientContext : GLib.Object, GLib.AsyncInitable, GLib.Initable, IContext {
    private bool _is_init;

    public GLib.DBusConnection connection { get; construct; }
    public IContextDBus proxy { get; }
    public ContextMode mode { get; construct; default = ContextMode.COMPOSITOR; }

    public async ClientContext.async(ContextMode mode = ContextMode.COMPOSITOR, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(mode: mode);
      yield this.init_async(GLib.Priority.DEFAULT, cancellable);
    }

    public ClientContext(ContextMode mode = ContextMode.COMPOSITOR, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      Object(mode: mode);
      this.init(cancellable);
    }

    public void invalidate_providers() {
      try {
        this.proxy.invalidate_providers();
      } catch (GLib.Error e) {
        GLib.error(_("Failed to execute \"%s\" on context \"%s\": %s:%d: %s"), "invalidate_providers", this.dbus_id, e.domain.to_string(), e.code, e.message);
      }
    }

    private bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this._is_init) {
        return true;
      }

      this._connection = GLib.Bus.get_sync(GLib.BusType.SESSION, cancellable);

      assert(this.dbus_id != null);
      this._proxy = this.connection.get_proxy_sync(this.dbus_id, "/com/expidus/genesis/Shell");
      this._is_init = true;
      return true;
    }

    private async bool init_async(int io_pri = GLib.Priority.DEFAULT, GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this._is_init) {
        return true;
      }

      this._connection = yield GLib.Bus.get(GLib.BusType.SESSION, cancellable);

      assert(this.dbus_id != null);
      this._proxy = yield this.connection.get_proxy(this.dbus_id, "/com/expidus/genesis/Shell");
      this._is_init = true;
      return true;
    }
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

    public void invalidate_providers() throws GLib.DBusError, GLib.IOError {
      this.context.invalidate_providers();
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
