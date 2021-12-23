namespace GenesisPortal {
	public errordomain SettingsPortalError {
		INVALID
	}

	private delegate GLib.HashTable<string, GLib.Variant> SettingsPortalReader();

	private struct SettingsPortalReaderEntry {
		public SettingsPortalReader read;
		public string ns;
	}

	[DBus(name = "org.freedesktop.impl.portal.Settings")]
	public class Settings {
		private GLib.Settings _settings;
		private SettingsPortalReaderEntry[] _entries;

		public uint version {
			get {
				return 0;
			}
		}

		public Settings() {
			this._settings = new GLib.Settings("com.expidus.genesis.desktop");
			this._entries = {};

			this.create_entry("org.freedesktop.appearance", () => {
				var tbl = new GLib.HashTable<string, GLib.Variant>(GLib.str_hash, GLib.str_equal);
				tbl.set("color-scheme", new GLib.Variant("u", this._settings.get_boolean("dark-theme") ? 1 : 0));
				return tbl;
			});

			this.create_entry("org.gnome.desktop.interface", () => {
				var tbl = new GLib.HashTable<string, GLib.Variant>(GLib.str_hash, GLib.str_equal);
				tbl.set("color-scheme", new GLib.Variant("s", this._settings.get_boolean("dark-theme") ? "prefer-dark" : "prefer-light"));
				tbl.set("gtk-theme", new GLib.Variant("s", "tokyonight_gtk"));
				tbl.set("icon-theme", new GLib.Variant("s", "papirus_tokyonight"));
				tbl.set("cursor-theme", new GLib.Variant("s", "redglass"));
				tbl.set("cursor-size", new GLib.Variant("i", 32));
				return tbl;
			});

			this.create_entry("org.gnome.desktop.interface.a11y", () => {
				var tbl = new GLib.HashTable<string, GLib.Variant>(GLib.str_hash, GLib.str_equal);
				tbl.set("high-contrast", new GLib.Variant("b", this._settings.get_boolean("high-contrast")));
				return tbl;
			});
		}

		private void create_entry(string ns, SettingsPortalReader reader) {
			var entry = SettingsPortalReaderEntry();
			entry.ns = ns;
			entry.read = reader;
			this._entries += entry;
		}

		public GLib.HashTable<string, GLib.HashTable<string, GLib.Variant>> read_all(string[] namespaces) throws GLib.DBusError, GLib.IOError {
			var nstbl = new GLib.HashTable<string, GLib.HashTable<string, GLib.Variant>>(GLib.str_hash, GLib.str_equal);

			foreach (var e in this._entries) {
				foreach (var ns in namespaces) {
					GLib.HashTable<string, GLib.Variant> tbl = e.read();
					if (GLib.PatternSpec.match_simple(ns, e.ns)) {
						nstbl.insert(e.ns, tbl);
						break;
					}
				}
			}
			return nstbl;
		}

		public GLib.Variant read(string ns, string key) throws GLib.Error {
			foreach (var e in this._entries) {
				if (e.ns == ns) {
					GLib.HashTable<string, GLib.Variant> tbl = e.read();

					if (tbl.contains(key)) {
						return new GLib.Variant("v", tbl.get(key));
					}
				}
			}

			throw new SettingsPortalError.INVALID("Key \"%s\" in namespace \"%s\" is not supported", key, ns);
		}

		public signal void setting_changed(string ns, string key, GLib.Variant value);
	}
}