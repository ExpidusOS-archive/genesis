namespace GenesisLogind {
  [DBus(name = "org.freedesktop.login1.Manager")]
	private interface ManagerClient : GLib.Object {
		public abstract string can_halt() throws GLib.Error;
		public abstract string can_hibernate() throws GLib.Error;
		public abstract string can_hybrid_sleep() throws GLib.Error;
		public abstract string can_power_off() throws GLib.Error;
		public abstract string can_reboot() throws GLib.Error;

		public abstract void halt(bool interactive) throws GLib.Error;
		public abstract void hibernate(bool interactive) throws GLib.Error;
		public abstract void power_off(bool interactive) throws GLib.Error;
		public abstract void reboot(bool interactive) throws GLib.Error;
		public abstract void suspend(bool interactive) throws GLib.Error;
		public abstract void suspend_then_hibernate(bool interactive) throws GLib.Error;
	}

  public class Manager : GLib.Object, GLib.Initable {
    private ManagerClient _client;
    
    public bool can_halt {
      get {
        try {
          return this._client.can_halt() == "yes";
        } catch (GLib.Error e) {
          return false;
        }
      }
    }
    
    public bool can_hibernate {
      get {
        try {
          return this._client.can_hibernate() == "yes";
        } catch (GLib.Error e) {
          return false;
        }
      }
    }
    
    public bool can_hybrid_sleep {
      get {
        try {
          return this._client.can_hybrid_sleep() == "yes";
        } catch (GLib.Error e) {
          return false;
        }
      }
    }
    
    public bool can_power_off {
      get {
        try {
          return this._client.can_power_off() == "yes";
        } catch (GLib.Error e) {
          return false;
        }
      }
    }
    
    public bool can_reboot {
      get {
        try {
          return this._client.can_reboot() == "yes";
        } catch (GLib.Error e) {
          return false;
        }
      }
    }
    
    public Manager(GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object();

      this.init(cancellable);
    }

    public bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      if (this._client == null) {
        this._client = GLib.Bus.get_proxy_sync(GLib.BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1", GLib.DBusProxyFlags.NONE, cancellable);
        return true;
      }
      return false;
    }

    public void halt(bool interactive = false) throws GLib.Error {
			this._client.halt(interactive);
		}

		public void hibernate(bool interactive = false) throws GLib.Error {
			this._client.hibernate(interactive);
		}

		public void poweroff(bool interactive = false) throws GLib.Error {
			this._client.power_off(interactive);
		}

		public void reboot(bool interactive = false) throws GLib.Error {
			this._client.reboot(interactive);
		}

		public void suspend(bool interactive = false) throws GLib.Error {
			this._client.suspend(interactive);
		}

		public void suspend_then_hibernate(bool interactive = false) throws GLib.Error {
			this._client.suspend_then_hibernate(interactive);
		}
  }
}