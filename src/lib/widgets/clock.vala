namespace GenesisWidgets {
  public class BaseClock : Gtk.Bin {
    private uint _timeout;

    public string format {
      get;
      set construct;
    }
    
    public string time {
      owned get {
        return new GLib.DateTime.now_local().format(this.format);
      }
    }

    construct {
      if (this.format == null) this.format = "%c";
      
      this.notify["format"].connect(() => this.update_clock());
      this._timeout = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 1, () => {
        this.update_clock();
        return true;
      });
    }
    
    ~BaseClock() {
      if (this._timeout > 0) {
        GLib.Source.remove(this._timeout);
        this._timeout = 0;
      }
    }
    
    public virtual void update_clock() {}
  }
  
  public class SimpleClock : BaseClock {
    private Gtk.Label _label;

    construct {
      this._label = new Gtk.Label(this.time);
      this.add(this._label);
    }

    public override void update_clock() {
      this._label.label = this.time;
    }
  }
}