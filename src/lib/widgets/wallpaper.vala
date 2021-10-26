namespace Genesis {
   public enum WallpaperStyle {
    NONE,
    CENTERED,
    SCALED,
    STRETCHED
  }

	public class BaseWallpaper : Gtk.Box, Widget {
		private string? _path;
		private WallpaperStyle _style;
		private Gtk.MediaFile? _video;
		private ulong _video_redraw = 0;

		public string? path {
			owned get {
				return this.get_file_path();
			}
			set construct {
				this.set_file_path(value);
			}
		}

		public WallpaperStyle style {
			get {
				return this._style;
			}
			set construct {
				this._style = value;
				this.queue_draw();
			}
		}

		construct {
			this.get_style_context().add_class("genesis-wallpaper");
		}

		protected string get_file_path() {
			return this._path;
		}

		protected void set_file_path(string? val) {
			if (this._video != null && this._video_redraw > 0) {
				this._video.disconnect(this._video_redraw);
				this._video_redraw = 0;
			}
			this._path = val;
			this._video = null;
			this.queue_draw();
		}

		public void draw(Gtk.Snapshot snapshot, WallpaperStyle style, string path) {
			Graphene.Rect rect = Graphene.Rect.zero();
			rect.init(0, 0, this.get_width(), this.get_height());
			string mime = GLib.ContentType.get_mime_type(path.split(".")[path.split(".").length - 1]);
			if (mime == null) return;
			switch (mime) {
				case "png":
				case "jpg":
				case "jpeg":
					{
						Gdk.Pixbuf? pixbuf = null;
						double x = 0;
						double y = 0;
						switch (style) {
							case WallpaperStyle.NONE:
								try {
									pixbuf = new Gdk.Pixbuf.from_file(path);
								} catch (GLib.Error e) {}
								break;
							case WallpaperStyle.CENTERED:
								try {
									pixbuf = new Gdk.Pixbuf.from_file(path);
									x = (this.get_width() / 2) - (pixbuf.width / 2);
									y = (this.get_height() / 2) - (pixbuf.height / 2);
								} catch (GLib.Error e) {}
								break;
							case WallpaperStyle.SCALED:
								try {
									pixbuf = new Gdk.Pixbuf.from_file_at_scale(path, this.get_width(), this.get_height(), true);
								} catch (GLib.Error e) {}
								break;
							case WallpaperStyle.STRETCHED:
								try {
									pixbuf = new Gdk.Pixbuf.from_file_at_size(path, this.get_width(), this.get_height());
								} catch (GLib.Error e) {}
								break;
						}
						if (pixbuf != null) {
							var node = new Gsk.CairoNode(rect);
							var cr = node.get_draw_context();
							Gdk.cairo_set_source_pixbuf(cr, pixbuf, x, y);
							cr.paint();
							snapshot.append_node(node);
						}
					}
					break;
				case "mp4":
					if (this._video == null) {
						this._video = Gtk.MediaFile.for_filename(path);
						this._video.muted = true;
						this._video.volume = 0.0;
						this._video.loop = true;
						this._video_redraw = this._video.invalidate_contents.connect(() => this.queue_draw());
						this._video.open();
						this._video.play_now();
					}

					this._video.snapshot(snapshot, this.get_width(), this.get_height());
					break;
			}
		}

		public override void snapshot(Gtk.Snapshot snapshot) {
			if (this.path != null) {
				this.draw(snapshot, this.style, this.path);
			}

			base.snapshot(snapshot);
		}
	}

	public class SettingsWallpaper : BaseWallpaper {
		private string _schema_id;
		private string _path_key;
		private string _style_key;
		private ulong _notify_id = 0;
		private GLib.Settings _settings;

		public string schema_id {
			get {
				return this._schema_id;
			}
			set {
				this.clear_notify_id();

				this._schema_id = value;
				this._settings = new GLib.Settings(this._schema_id);

				this.set_notify_id();
				this.queue_draw();
			}
		}

		public string path_key {
			get {
				return this._path_key;
			}
			set {
				this._path_key = value;

				this.set_notify_id();
				this.queue_draw();
			}
		}

		public string style_key {
			get {
				return this._style_key;
			}
			set {
				this._style_key = value;

				this.set_notify_id();
				this.queue_draw();
			}
		}

		~SettingsWallpaper() {
			this.clear_notify_id();
		}

		public override void snapshot(Gtk.Snapshot snapshot) {
			if (this.schema_id == null) this.schema_id = "com.expidus.genesis.desktop";
			if (this.path_key == null) this.path_key = "wallpaper";
			if (this.style_key == null) this.style_key = "wallpaper-style";

			this.set_notify_id();

			var path = this._settings.get_string(this.path_key);
			var style = (WallpaperStyle)this._settings.get_enum(this.style_key);
			if (path != null) {
				this.draw(snapshot, style, path);
			}

			base.snapshot(snapshot);
		}

		private void set_notify_id() {
			if (this._settings != null && this._notify_id == 0) {	
				this._notify_id = this._settings.changed.connect((key) => {
					if (key == this._path_key || key == this._style_key) {
						this.queue_draw();
					}
				});
			}
		}

		private void clear_notify_id() {
			if (this._settings != null && this._notify_id > 0) {
				this._settings.disconnect(this._notify_id);
				this._notify_id = 0;
			}
		}
	}
}