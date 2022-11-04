namespace GenesisShellGtk3 {
  public interface IDashIndicator : Gtk.Widget {
    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public abstract GenesisShell.Monitor monitor { get; construct; }
    public abstract string id { get; construct; }
    public abstract Gtk.Image icon { get; }

    public static new IDashIndicator @new(GLib.Type type, GenesisShell.Monitor monitor, string id) {
      return (IDashIndicator)GLib.Object.new(type, "monitor", monitor, "id", id);
    }
  }

  public abstract class DashIndicator : Gtk.ToggleButton, IDashIndicator {
    public GenesisShell.Monitor monitor { get; construct; }
    public string id { get; construct; }
    public Gtk.Image icon { get; }

    construct {
      this.get_style_context().add_class("genesis-shell-dash-indicator");

      this._icon = new Icon.for_monitor("error", this.monitor, 25.0);
      this._icon.halign = Gtk.Align.CENTER;
      this._icon.valign = Gtk.Align.CENTER;
      this._icon.bind_property("visible", this, "visible", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
      this.add(this._icon);

      this.halign = Gtk.Align.CENTER;
      this.valign = Gtk.Align.CENTER;
    }

    public static new DashIndicator @new(GLib.Type type, GenesisShell.Monitor monitor, string id) {
      return (DashIndicator)GLib.Object.new(type, "monitor", monitor, "id", id);
    }
  }

  public class DashboardWidget : Gtk.Bin, GenesisShell.IUIElement {
    public const double UNIT_SIZE = 250.0;
    public const double ACTION_BUTTON_UNIT_SIZE = 25.0;
    public const double ACTION_BUTTON_ICON_UNIT_SIZE = 15.0;

    private Gtk.Adjustment _scroll_adjust;
    private Gtk.ScrolledWindow _scroll;
    private Gtk.Viewport _scroll_view;
    private Gtk.Box _indicators_box;
    private GLib.List <IDashIndicator> _indicators;
    private Gtk.Box _actions;
    private Hdy.ViewSwitcherTitle _calevents_title;
    private Gtk.Stack _calevents_stack;

    public Gtk.Box content { get; }
    public TokyoGtk.CalendarEvents calevents { get; }

    public GenesisShell.UIElementKind kind {
      get {
        return GenesisShell.UIElementKind.DESKTOP;
      }
    }

    public GenesisShell.Context context {
      get {
        return this.monitor.context;
      }
    }

    public GenesisShell.Monitor monitor { get; construct; }

    public GLib.List <unowned IDashIndicator> indicators {
      owned get {
        return this._indicators.copy();
      }
    }

    internal DashboardWidget(GenesisShell.Monitor monitor) {
      Object(monitor: monitor);
    }

    private async void init_async() {
#if HAS_LIBNM
      try {
        this.add_indicator(yield new DashIndicators.WiFi(this.monitor, "wifi-0"));
      } catch (GLib.Error e) {
        GLib.warning(_("WiFi failed to initialize: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
      }
#endif
    }

    construct {
      this._scroll_adjust = new Gtk.Adjustment(0, 0, 100.0, 1.0, 10.0, 0.0);
      this._scroll = new Gtk.ScrolledWindow(null, this._scroll_adjust);
      this._scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
      this._scroll.shadow_type = Gtk.ShadowType.NONE;
      this.add(this._scroll);

      this._scroll_view = new Gtk.Viewport(null, this._scroll_adjust);
      this._scroll.add(this._scroll_view);

      var spacing = GenesisShell.Math.scale(this.monitor.dpi, 1.0);
      var margin = GenesisShell.Math.scale(this.monitor.dpi, 1.0);

      this._content = new Gtk.Box(Gtk.Orientation.VERTICAL, spacing);
      this._content.margin_top = margin;
      this._content.margin_bottom = margin;
      this._content.margin_start = margin;
      this._content.margin_end = margin;
      this._content.hexpand = true;
      this._content.vexpand = true;
      this._scroll_view.add(this._content);

      this._indicators_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, spacing);
      this._indicators_box.halign = Gtk.Align.CENTER;
      this._indicators_box.valign = Gtk.Align.START;
      this._indicators_box.hexpand = true;
      this._indicators_box.vexpand = true;
      this._content.pack_start(this._indicators_box);

      this._actions = new Gtk.Box(Gtk.Orientation.HORIZONTAL, spacing);
      this._actions.halign = Gtk.Align.CENTER;
      this._actions.valign = Gtk.Align.END;
      this._actions.hexpand = true;
      this._actions.vexpand = true;

#if HAS_GIO_UNIX
      this.add_action_button("settings-symbolic").clicked.connect(() => {
        try {
          var launch_ctx = this.get_display().get_app_launch_context();
          var app_info = new GLib.DesktopAppInfo("com.expidus.genesis.settings");
          if (app_info != null) app_info.launch_uris_as_manager(new GLib.List<string>(), launch_ctx, GLib.SpawnFlags.SEARCH_PATH_FROM_ENVP, null, null);
        } catch (GLib.Error e) {
          GLib.warning(_("Settings failed to open: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
        }
      });
#endif

      this.add_action_button("system-log-out-symbolic").clicked.connect(() => this.context.shutdown());
      this.add_action_button("system-lock-screen-symbolic").clicked.connect(() => {
        this.context.ui_provider.action(GenesisShell.UIElementKind.LOCK, GenesisShell.UIActionKind.TOGGLE_OPEN, {}, {});
      });

      if (this.context.mode != GenesisShell.ContextMode.BIG_PICTURE) {
        this.add_action_button("system-switch-user-symbolic").clicked.connect(() => {});
        this.add_action_button("system-shutdown-symbolic").clicked.connect(() => {});
        this.add_action_button("system-reboot-symbolic").clicked.connect(() => {});
      }

      this._content.pack_end(this._actions);

      this._calevents = new TokyoGtk.CalendarEvents();
      this._calevents.halign = Gtk.Align.FILL;
      this._calevents.valign = Gtk.Align.END;
      this._calevents.spacing = spacing;
      this._content.pack_end(this._calevents);

      this.init_async.begin((obj, ctx) => this.init_async.end(ctx));
    }

    private Gtk.Button add_action_button(string icon_name) {
      var button = new ButtonBox.for_monitor(this.monitor, ACTION_BUTTON_UNIT_SIZE);
      button.image = new Icon.for_monitor(icon_name, this.monitor, ACTION_BUTTON_ICON_UNIT_SIZE);
      button.always_show_image = true;
      this._actions.add(button);
      return button;
    }

    private unowned GLib.List <IDashIndicator> find_indicator(IDashIndicator indicator) {
      return this._indicators.find_custom(indicator, (a, b) => GLib.strcmp(a.id, b.id));
    }

    public bool has_indicator(IDashIndicator indicator) {
      return this.find_indicator(indicator) != null;
    }

    public void add_indicator(IDashIndicator indicator) {
      if (this.find_indicator(indicator) == null) {
        this._indicators.append(indicator);
        this._indicators_box.add(indicator);
        this.indicator_added(indicator);
      }
    }

    public void remove_indicator(IDashIndicator indicator) {
      unowned var elem = this.find_indicator(indicator);
      if (elem != null) {
        this.indicator_removed(elem.data);
        this._indicators_box.remove(elem.data);
        this._indicators.remove_link(elem);
      }
    }

    private int get_width() {
      return GenesisShell.Math.scale(this.monitor.dpi, UNIT_SIZE);
    }

    private int get_height() {
      var monitor = this.monitor as Monitor;
      assert(monitor != null);

      int min_height;
      int nat_height;
      monitor.panel_widget.get_preferred_height(out min_height, out nat_height);
      return this.monitor.mode.height - (15 + nat_height);
    }

    public override void size_allocate(Gtk.Allocation alloc) {
      if (this.context.mode == GenesisShell.ContextMode.BIG_PICTURE) {
        var monitor = this.monitor as Monitor;
        assert(monitor != null);

        int min_height;
        int nat_height;
        monitor.panel_widget.get_preferred_height(out min_height, out nat_height);

        var edge = this.monitor.mode.width * 0.01;
        alloc.x = (this.monitor.x + this.monitor.mode.width) - (int)(edge / 2);
        alloc.y = this.monitor.y + min_height + 10;

        alloc.width = this.get_width();
        alloc.height = this.get_height();
      }
      base.size_allocate(alloc);
    }

    public override void get_preferred_width(out int min_width, out int nat_width) {
      min_width = nat_width = this.get_width();
    }

    public override void get_preferred_height(out int min_height, out int nat_height) {
      min_height = nat_height = this.get_height();
    }

    public signal void indicator_added(IDashIndicator indicator);
    public signal void indicator_removed(IDashIndicator indicator);
  }
}
