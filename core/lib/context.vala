namespace GenesisShell {
  internal Context? global_context;

  [DBus(name = "com.expidus.genesis.Shell")]
  public interface IContextDBus : GLib.Object {
  }

  public sealed class Context : GLib.Object, GLib.AsyncInitable, GLib.Initable {
    private bool _is_init = false;

    internal DBusContext dbus { get; }

    public static async unowned Context get_global_async(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (global_context == null) {
        global_context = yield new Context.async(cancellable);
      }
      return global_context;
    }

    public static unowned Context get_global_sync(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (global_context == null) {
        global_context = new Context(cancellable);
      }
      return global_context;
    }

    internal async Context.async(GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object();
      yield this.init_async(GLib.Priority.DEFAULT, cancellable);
    }

    internal Context(GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object();
      this.init(cancellable);
    }

    private async bool init_async(int io_pri, GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

      this._dbus = yield new DBusContext.make_async_connection(this, cancellable);
      return true;
    }

    private bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._is_init) return true;
      this._is_init = true;

      this._dbus = new DBusContext.make_sync_connection(this, cancellable);
      return true;
    }
  }

  internal sealed class DBusContext : GLib.Object, IContextDBus, GLib.Initable {
    private bool _is_init = false;
    private uint _obj_id;

    public GLib.DBusConnection connection { get; construct; }
    public Context context { get; construct; }

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
      this._is_init = true;

      this._obj_id = this.connection.register_object("/com/expidus/genesis/Shell", (IContextDBus)this);
      return true;
    }
  }
}
