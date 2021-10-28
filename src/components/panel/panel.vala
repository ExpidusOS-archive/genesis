namespace Genesis {
	public class PanelApplication : Adw.Application {
		private Component _comp;
		private GLib.List<Panel*> _windows;
		private GLib.DBusConnection? _conn = null;

		[DBus(visible = false)]
		public Component component {
			get {
				return this._comp;
			}
		}

		[DBus(visible = false)]
		public GLib.DBusConnection? conn {
			get {
				return this._conn;
			}
		}

		public PanelApplication() {
			Object(application_id: "com.expidus.GenesisPanel");
			this.set_option_context_parameter_string(_("- Genesis Shell Panel Component"));

			this._comp = new Component();
			this._windows = new GLib.List<Panel*>();

			this._comp.killed.connect(() => {
				GLib.Process.exit(0);
			});

			init_widgets();
		}

		public override bool dbus_register(GLib.DBusConnection conn, string obj_path) throws GLib.Error {
			if (!base.dbus_register(conn, obj_path)) return false;

			conn.register_object(obj_path, this._comp);
			this._conn = conn;
			return true;
		}

		public override void activate() {
			this._comp.default_id = "genesis_panel";

			this._comp.layout_changed.connect((monitor) => {
				foreach (var win in this._windows) {
					if (win->monitor_name == monitor) {
						this._windows.remove(win);
						delete win;
					}
				}

				var wins = this._comp.get_widgets(monitor);
				foreach (var obj in wins) {
					if (obj == null && !(obj is Panel)) continue;
					var win = (Panel)obj;
					win.hide();
					win.monitor_name = monitor;
					win.application = this;
					win.show();
					this._windows.append(win);
				}
			});

			this._comp.monitor_changed.connect((monitor, added) => {
				foreach (var win in this._windows) {
					if (win->monitor_name == monitor) {
						this._windows.remove(win);
						delete win;
					}
				}

				if (added) {
					var wins = this._comp.get_widgets(monitor);
					foreach (var obj in wins) {
						if (obj == null && !(obj is Panel)) continue;
						var win = (Panel)obj;
						win.hide();
						win.monitor_name = monitor;
						win.application = this;
						win.show();
						this._windows.append(win);
					}
				}
			});

			new GLib.MainLoop().run();
		}
	}

	public static int main(string[] argv) {
		GLib.Intl.setlocale(GLib.LocaleCategory.ALL, ""); 
		GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, DATADIR + "/locale");
		GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
		GLib.Intl.textdomain(GETTEXT_PACKAGE);

		GLib.Environment.set_application_name(GETTEXT_PACKAGE);
		GLib.Environment.set_prgname(GETTEXT_PACKAGE);
		Gdk.set_allowed_backends("x11");
		Gtk.init();
		Adw.init();
		return new PanelApplication().run(argv);
	}
}

[CCode(cheader_filename="build.h")]
extern const string GETTEXT_PACKAGE;