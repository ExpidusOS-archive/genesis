namespace GenesisBluetooth {
  [DBus(name = "org.bluez.Adapter1")]
  public interface Adapter : GLib.Object {
    public abstract void remove_device(GLib.ObjectPath device) throws Error;
    public abstract void set_discovery_filter(GLib.HashTable<string, Variant> properties) throws Error;
    public abstract void start_discovery() throws Error;
    public abstract void stop_discovery() throws Error;

    public abstract string[] UUIDs { owned get; }
    public abstract bool discoverable { get; set; }
    public abstract bool discovering { get; }
    public abstract bool pairable { get; set; }
    public abstract bool powered { get; set; }
    public abstract string address { owned get; }
    public abstract string alias { owned get; set; }
    public abstract string modalias { owned get; }
    public abstract string name { owned get; }
    public abstract uint @class { get; }
    public abstract uint discoverable_timeout { get; set; }
    public abstract uint pairable_timeout { get; set; }
  }
  
  [DBus(name = "org.bluez.Device1")]
  public interface Device : GLib.Object {
    public abstract void cancel_pairing() throws Error;
    public abstract async void connect() throws Error;
    public abstract void connect_profile(string UUID) throws Error;
    public abstract async void disconnect() throws Error;
    public abstract void disconnect_profile(string UUID) throws Error;
    public abstract void pair() throws Error;

    public abstract string[] UUIDs { owned get; }
    public abstract bool blocked { owned get; set; }
    public abstract bool connected { owned get; }
    public abstract bool legacy_pairing { owned get; }
    public abstract bool paired { owned get; }
    public abstract bool trusted { owned get; set; }
    public abstract int16 RSSI { owned get; }
    public abstract GLib.ObjectPath adapter { owned get; }
    public abstract string address { owned get; }
    public abstract string alias { owned get; set; }
    public abstract string icon { owned get; }
    public abstract string modalias { owned get; }
    public abstract string name { owned get; }
    public abstract uint16 appearance { owned get; }
    public abstract uint32 @class { owned get; }
  }
}