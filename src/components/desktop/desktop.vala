namespace Genesis {
		public class DesktopApplication : Gtk.Application {
				private Component _comp;
				private GLib.List<Desktop*> _windows;
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

				public DesktopApplication() {
						Object(application_id: "com.expidus.GenesisDesktop");
						this.set_option_context_parameter_string(_("- Genesis Shell Desktop Component"));

						this._comp = new Component();
						this._windows = new GLib.List<Desktop*>();

						this._comp.killed.connect(() => {
								GLib.Process.exit(0);
						});

						init_widgets();
						typeof (Desktop).name();
				}

				private string? get_xdg_dir(string type) {
						switch (type) {
								case "HOME":
										return GLib.Environment.get_home_dir();
								case "USER_CACHE":
										return GLib.Environment.get_user_data_dir();
								case "USER_CONFIG":
										return GLib.Environment.get_user_config_dir();
								case "USER_DATA":
										return GLib.Environment.get_user_data_dir();
								default:
										GLib.UserDirectory dir;
										switch (type) {
												case "DESKTOP":
														dir = GLib.UserDirectory.DESKTOP;
														break;
												case "DOCUMENTS":
														dir = GLib.UserDirectory.DOCUMENTS;
														break;
												case "DOWNLOADS":
														dir = GLib.UserDirectory.DOWNLOAD;
														break;
												case "MUSIC":
														dir = GLib.UserDirectory.MUSIC;
														break;
												case "PICTURES":
														dir = GLib.UserDirectory.PICTURES;
														break;
												case "PUBLIC_SHARE":
														dir = GLib.UserDirectory.PUBLIC_SHARE;
														break;
												case "TEMPLATES":
														dir = GLib.UserDirectory.TEMPLATES;
														break;
												case "VIDEOS":
														dir = GLib.UserDirectory.VIDEOS;
														break;
												default:
														return null;
										}
										return GLib.Environment.get_user_special_dir(dir);
						}
				}

				public string? get_xdg_display(string type) {
						switch (type) {
								case "HOME": return _("Home");
								case "USER_CACHE": return _("Cache");
								case "USER_CONFIG": return _("Configuration");
								case "USER_DATA": return _("Data");
								case "DESKTOP": return _("Desktop");
								case "DOCUMENTS": return _("Documents");
								case "DOWNLOADS": return _("Downloads");
								case "MUSIC": return _("Music");
								case "PICTURES": return _("Pictures");
								case "PUBLIC_SHARE": return _("Public Share");
								case "TEMPLATES": return _("Templates");
								case "VIDEOS": return _("Videos");
						}
						return null;
				}

				private void load_apps(GLib.Menu menu) {
						var apps = GLib.AppInfo.get_all();
						apps.sort((a, b) => {
								return GLib.strcmp(a.get_display_name(), b.get_display_name());
						});
						menu.remove_all();
						foreach (var app in apps) {
								if (app.should_show()) {
										var item = new GLib.MenuItem(app.get_display_name(), "app.launch");
										item.set_action_and_target("app.launch", "s", app.get_id());
										menu.append_item(item);
								}
						}
				}

				private void build_menu() {
						var app_menu = new GLib.Menu();
						{
								var menu = new GLib.Menu();

								menu.append(_("Settings"), "app.settings");
								menu.append(_("About"), "app.about");

								{
										var submenu = new GLib.Menu();

										string[] dirs = { "HOME", "DESKTOP", "DOCUMENTS", "DOWNLOADS", "MUSIC", "PICTURES", "VIDEOS" };
										foreach (var str in dirs) {
												var dir = this.get_xdg_dir(str);
												var disp = this.get_xdg_display(str);
												if (dir == null || disp == null) continue;

												var item = new GLib.MenuItem(disp, "app.dir");
												item.set_action_and_target("app.dir", "s", dir);
												submenu.append_item(item);
										}

										menu.append_section(null, submenu);
								}

								app_menu.append_submenu(_("Genesis"), menu);
						}

						{
								var menu = new GLib.Menu();
								this.load_apps(menu);
								GLib.AppInfoMonitor.@get().changed.connect(() => {
										this.load_apps(menu);
										this.set_menubar(app_menu);
								});
								app_menu.append_submenu(_("Applications"), menu);
						}
						this.set_menubar(app_menu);
				}

				public override void startup() {
						base.startup();

						{
								var action = new GLib.SimpleAction("settings", null);
								action.activate.connect(() => {
										try {
												var app = GLib.AppInfo.create_from_commandline(BINDIR + "/genesis-settings", _("Genesis Settings"), GLib.AppInfoCreateFlags.NONE);
												app.launch(null, null);
										} catch (GLib.Error e) {}
								});
								this.add_action(action);
						}

						{
								var action = new GLib.SimpleAction("about", null);
								action.activate.connect(() => {
										try {
												var app = GLib.AppInfo.create_from_commandline(BINDIR + "/genesis-about", _("Genesis About"), GLib.AppInfoCreateFlags.NONE);
												app.launch(null, null);
										} catch (GLib.Error e) {}
								});
								this.add_action(action);
						}

						{
								var action = new GLib.SimpleAction("launch", GLib.VariantType.STRING);
								action.activate.connect((param) => {
										var app = new GLib.DesktopAppInfo(param.get_string());
										try {
												app.launch(null, null);
										} catch (GLib.Error e) {}
								});
								this.add_action(action);
						}

						{
								var action = new GLib.SimpleAction("dir", GLib.VariantType.STRING);
								action.activate.connect((param) => {
										try {
												GLib.AppInfo.launch_default_for_uri("file://" + param.get_string(), null);
										} catch (GLib.Error e) {}
								});
								this.add_action(action);
						}

						this.build_menu();
				}

				public override bool dbus_register(GLib.DBusConnection conn, string obj_path) throws GLib.Error {
						if (!base.dbus_register(conn, obj_path)) return false;

						conn.register_object(obj_path, this._comp);
						this._conn = conn;
						return true;
				}

				public override void activate() {
						this._comp.default_id = "genesis_desktop";

						this._comp.layout_changed.connect((monitor) => {
								foreach (var win in this._windows) {
										if (win->monitor_name == monitor) {
												this._windows.remove(win);
												delete win;
										}
								}

								var wins = this._comp.get_widgets(monitor);
								foreach (var obj in wins) {
										if (obj == null && !(obj is Desktop)) continue;
										var win = (Desktop)obj;
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
												if (obj == null && !(obj is Desktop)) continue;
												var win = (Desktop)obj;
												win.hide();
												win.monitor_name = monitor;
												win.application = this;
												win.show();
												this._windows.append(win);
										}
								}
						});

						GLib.Timeout.add(600, () => {
							foreach (var p in this._windows) p->update_margins();
							return true;
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
				return new DesktopApplication().run(argv);
		}
}

[CCode(cheader_filename="build.h")]
extern const string GETTEXT_PACKAGE;