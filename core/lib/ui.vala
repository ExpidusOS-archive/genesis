namespace GenesisShell {
  public enum UIElementKind {
    CUSTOM = 0,
    PANEL,
    DESKTOP,
    NOTIFICATION,
    APPS,
    DASH;

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

    public bool action(UIElementKind elem, UIActionKind action, ...) {
      return this.actionv(elem, action, va_list());
    }

    public bool actionv(UIElementKind elem, UIActionKind action, va_list ap) {
      var dup = va_list.copy(ap);

      var i = 0;
      for (var item = dup.arg <void *>(); item != null; item = dup.arg <void *>()) {
        i++;
      }
      assert(i % 2 == 0);

      string[]     names  = {};
      GLib.Value[] values = {};

      for (var x = 0; x < i; x += 2) {
        // FIXME: prevent segfault
        names[x]  = ap.arg <string>();
        values[x] = ap.arg <GLib.Value>();
      }

      return this.action_with_properties(elem, action, names, values);
    }

    public virtual signal bool action_with_properties(UIElementKind elem, UIActionKind action, string[] names, GLib.Value[] values) {
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
    public bool action(UIActionKind action, ...) {
      return this.actionv(action, va_list());
    }

    public bool actionv(UIActionKind action, va_list ap) {
      var dup = va_list.copy(ap);

      var i = 0;
      for (var item = dup.arg <void *>(); item != null; item = dup.arg <void *>()) {
        i++;
      }
      assert(i % 2 == 0);

      string[]     names  = {};
      GLib.Value[] values = {};

      for (var x = 0; x < i; x += 2) {
        names[x]  = ap.arg <string>();
        values[x] = ap.arg <GLib.Value>();
      }

      return this.action_with_properties(action, names, values);
    }

    public abstract signal bool action_with_properties(UIActionKind action, string[] names, GLib.Value[] values);
  }
}
