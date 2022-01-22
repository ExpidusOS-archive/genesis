namespace GenesisBluetooth {
  public class Manager : GLib.Object, GLib.Initable {
    private GLib.DBusObjectManagerClient _obj_manager;
    private GLib.HashTable<string, Adapter> _adapters;
    private GLib.HashTable<string, Device> _devices;
    
    public GLib.List<weak Adapter> adapters {
      owned get {
        return this._adapters.get_values();
      }
    }
    
    public GLib.List<weak Device> devices {
      owned get {
        return this._devices.get_values();
      }
    }
    
    construct {
      this._adapters = new GLib.HashTable<string, Adapter>(GLib.str_hash, GLib.str_equal);
      this._devices = new GLib.HashTable<string, Device>(GLib.str_hash, GLib.str_equal);
    }

    public Manager(GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object();

      this.init(cancellable);
    }

    public bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._obj_manager == null) {
        this._obj_manager = new GLib.DBusObjectManagerClient.for_bus_sync(GLib.BusType.SYSTEM, GLib.DBusObjectManagerClientFlags.NONE, "org.bluez", "/", null);
        
        this._obj_manager.interface_added.connect((obj, iface) => {
          try {
            switch (iface.get_info().name) {
              case "org.bluez.Adapter1":
                var adapter = this._obj_manager.get_connection().get_proxy_sync<Adapter>("org.bluez", obj.get_object_path(), GLib.DBusProxyFlags.NONE, null);
                this._adapters.set(obj.get_object_path(), adapter);
                this.adapter_added(adapter);
                break;
              case "org.bluez.Device1":
                var device = this._obj_manager.get_connection().get_proxy_sync<Device>("org.bluez", obj.get_object_path(), GLib.DBusProxyFlags.NONE, null);
                this._devices.set(obj.get_object_path(), device);
                this.device_added(device);
                break;
            }
          } catch (GLib.Error e) {}
        });
        
        this._obj_manager.interface_removed.connect((obj, iface) => {
          try {
            switch (iface.get_info().name) {
              case "org.bluez.Adapter1":
                var adapter = this._obj_manager.get_connection().get_proxy_sync<Adapter>("org.bluez", obj.get_object_path(), GLib.DBusProxyFlags.NONE, null);
                this.adapter_removed(adapter);
                this._adapters.remove(obj.get_object_path());
                break;
              case "org.bluez.Device1":
                var device = this._obj_manager.get_connection().get_proxy_sync<Device>("org.bluez", obj.get_object_path(), GLib.DBusProxyFlags.NONE, null);
                this.device_removed(device);
                this._devices.remove(obj.get_object_path());
                break;
            }
          } catch (GLib.Error e) {}
        });
        
        var objs = this._obj_manager.get_objects();
        foreach (var obj in objs) {
          if (obj.get_interface("org.bluez.Adapter1") != null) {
            try {
              var adapter = this._obj_manager.get_connection().get_proxy_sync<Adapter>("org.bluez", obj.get_object_path(), GLib.DBusProxyFlags.NONE, null);
              this._adapters.set(obj.get_object_path(), adapter);
              this.adapter_added(adapter);
            } catch (GLib.Error e) {}
          } else if (obj.get_interface("org.bluez.Device1") != null) {
            try {
              var device = this._obj_manager.get_connection().get_proxy_sync<Device>("org.bluez", obj.get_object_path(), GLib.DBusProxyFlags.NONE, null);
              this._devices.set(obj.get_object_path(), device);
              this.device_added(device);
            } catch (GLib.Error e) {}
          }
        }
        return true;
      }
      return false;
    }
    
    public Device? find_connected(Adapter? adapter = null) throws GLib.Error {
      foreach (var device in this.devices) {
        if (device.connected) {
          if (adapter == null) return device;
          else {
            if (this._adapters.get(device.adapter).address == adapter.address) return device;
          }
        }
      }
      return null;
    }
    
    public signal void adapter_added(Adapter adapter);
    public signal void adapter_removed(Adapter adapter);

    public signal void device_added(Device device);
    public signal void device_removed(Device device);
  }
}