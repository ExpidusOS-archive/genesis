namespace GenesisWidgets {
  public enum WallpaperStyle {
		NONE = 0,
		CENTERED,
		SCALED,
		STRETCHED,
		TILED
	}

	public class Wallpaper : GLib.Object {
		public virtual string image { owned get; set construct; }
		public virtual WallpaperStyle style { get; set construct; }

		public Wallpaper() {
			Object();
		}

		public void draw(Cairo.Context cr, int width, int height) throws GLib.Error {
			switch (this.style) {
				case WallpaperStyle.NONE:
					var surf = new Cairo.ImageSurface.from_png(this.image);
					cr.set_source_surface(surf, 0, 0);
					break;
				case WallpaperStyle.CENTERED:
					var surf = new Cairo.ImageSurface.from_png(this.image);
					var x = (width / 2) - (surf.get_width() / 2);
					var y = (height / 2) - (surf.get_height() / 2);

					cr.set_source_surface(surf, x, y);
					break;
				case WallpaperStyle.SCALED:
					var pixbuf = new Gdk.Pixbuf.from_file_at_scale(this.image, width, height, false);
					Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0);
					break;
				case WallpaperStyle.STRETCHED:
					var pixbuf = new Gdk.Pixbuf.from_file_at_size(this.image, width, height);
					Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0);
					break;
				case WallpaperStyle.TILED:
					var surf = new Cairo.ImageSurface.from_png(this.image);

					var num_cols = width / surf.get_width();
					var num_rows = height / surf.get_height();

					for (var row = 0; row < num_rows; row++) {
						for (var col = 0; col < num_cols; col++) {
							var x = num_rows * row;
							var y = num_cols * col;

							cr.set_source_surface(surf, x, y);
							cr.paint();
						}
					}
					break;
			}

			cr.paint();
		}
	}

	public class WallpaperSettings : Wallpaper {
		private GLib.Settings _settings;
		private ulong _image_id;
		private ulong _style_id;
		private bool _is_loaded;
		
		public DevidentClient.Context devident { get; construct; }

		public override string image {
			owned get {
				var extra = "desktop";

				try {
					var dev = this.devident.get_default_device();
					if (dev.device_type == DevidentCommon.DeviceType.PHONE || dev.device_type == DevidentCommon.DeviceType.TABLET) extra = "mobile";
				} catch (GLib.Error e) {}
				
				return this.get_settings().get_string("wallpaper").replace("{system}", GenesisCommon.DATADIR + "/backgrounds/expidus/" + extra);
			}
			set construct {
				if (value != null) this.get_settings().set_string("wallpaper", value);
			}
		}

		public override WallpaperStyle style {
			get {
				return (WallpaperStyle)this.get_settings().get_enum("wallpaper-style");
			}
			set construct {
				if (this._is_loaded) this.get_settings().set_enum("wallpaper-style", value);
			}
		}
		
		public WallpaperSettings(DevidentClient.Context devident) {
			Object(devident: devident);
		}

		~WallpaperSettings() {
			if (this._image_id > 0) {
				this.get_settings().disconnect(this._image_id);
				this._image_id = 0;
			}

			if (this._style_id > 0) {
				this.get_settings().disconnect(this._style_id);
				this._style_id = 0;
			}
		}

		construct {
			var settings = this.get_settings();
			
			this._image_id = settings.changed["wallpaper"].connect(() => this.notify_property("image"));
			this._style_id = settings.changed["wallpaper-style"].connect(() => this.notify_property("style"));

			this._is_loaded = true;
		}

		private GLib.Settings get_settings() {
			if (this._settings == null) this._settings = new GLib.Settings("com.expidus.genesis.desktop");
			return this._settings;
		}
	}
}