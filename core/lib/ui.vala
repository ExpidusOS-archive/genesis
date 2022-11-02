namespace GenesisShell {
  public enum UIElementKind {
    CUSTOM = 0,
    PANEL,
    DESKTOP,
    NOTIFICATION,
    APPS,
    DASH,
    FILE_BROWSER,
    APP_BROWSER;

    public static uint n_values() {
      var enumc = (GLib.EnumClass)typeof(UIElementKind).class_ref();
      return enumc.n_values;
    }
  }

  public enum UIActionKind {
    CUSTOM = 0,
    OPEN,
    CLOSE,
    HIDE,
    SHOW,
    TOGGLE_OPEN,
    TOGGLE_SHOW;

    public static uint n_values() {
      var enumc = (GLib.EnumClass)typeof(UIActionKind).class_ref();
      return enumc.n_values;
    }
  }

  public interface IUIProvider : GLib.Object {
    public abstract Context context { get; construct; }

    public GLib.HashTable <UIElementKind, GLib.List <string> > monitor_list_all(Monitor monitor) {
      var tbl = new GLib.HashTable <UIElementKind, GLib.List <string> >(GLib.int_hash, GLib.int_equal);

      for (var i = 0; i < UIElementKind.n_values(); i++) {
        var kind = (UIElementKind)i;
        var list = this.monitor_list_ids_for_kind(monitor, kind);
        tbl.set(kind, list.copy_deep(GLib.strdup));
      }
      return tbl;
    }

    public abstract GLib.List <string> monitor_list_ids_for_kind(Monitor monitor, UIElementKind kind);
    public abstract IUIElement ? for_monitor(Monitor monitor, UIElementKind kind, string ?id);

    public virtual signal GLib.Value action(UIElementKind elem, UIActionKind action, string[] names, GLib.Value[] values) {
      return false;
    }
  }

  public interface IUIElement : GLib.Object {
    public abstract UIElementKind kind { get; }

    public virtual string ?id {
      get {
        return null;
      }
    }
  }

  public interface IUIActioner : GLib.Object, IUIElement {
    public abstract signal GLib.Value action(UIActionKind action, string[] names, GLib.Value[] values);
  }
}
