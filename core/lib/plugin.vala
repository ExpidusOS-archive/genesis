namespace GenesisShell {
  public interface IPlugin : GLib.Object {
    public abstract Context context { get; construct; }
    public abstract Vdi.Container container { get; }

    public virtual GLib.OptionEntry[] get_options() {
      return { { null } };
    }
  }

  public abstract class AsyncPlugin : GLib.Object, IPlugin {
    public Context context { get; construct; }
    public Vdi.Container container { get; }

    construct {
      this._container = new Vdi.Container();
    }

    public abstract async void activate(GLib.Cancellable? cancellable = null) throws GLib.Error;
    public abstract async void deactivate(GLib.Cancellable? cancellable = null) throws GLib.Error;
  }

  public abstract class Plugin : GLib.Object, IPlugin {
    public Context context { get; construct; }
    public Vdi.Container container { get; }

    construct {
      this._container = new Vdi.Container();
    }

    public abstract void activate(GLib.Cancellable? cancellable = null) throws GLib.Error;
    public abstract void deactivate(GLib.Cancellable? cancellable = null) throws GLib.Error;
  }
}
