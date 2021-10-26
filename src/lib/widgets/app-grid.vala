namespace Genesis {
	public enum AppGridSelectionMode {
		NONE = 0,
		SINGLE,
		MULTI
	}

	public class AppGrid : Bin, Widget {
		private AppGridSelectionMode _selection_mode;
		private Gtk.GridView? _grid = null;
		private GLib.ListModel? _model = null;
		private uint _max_columns;
		private uint _min_columns;
		private Gtk.Orientation _ori;

		public AppGridSelectionMode selection_mode {
			get {
				return this._selection_mode;
			}
			set construct {
				this._selection_mode = value;
				this.update_model();
			}
		}

		public GLib.ListModel? model {
			get {
				return this._model;
			}
			set construct {
				this._model = value;
				this.update_model();
			}
		}
		
		public uint max_columns {
			get {
				return this._max_columns;
			}
			set construct {
				this._max_columns = value;
				if (this._grid != null) this._grid.max_columns = value;
			}
		}
		
		public uint min_columns {
			get {
				return this._min_columns;
			}
			set construct {
				this._min_columns = value;
				if (this._grid != null) this._grid.min_columns = value;
			}
		}

		public Gtk.Adjustment? hadjustment {
			get {
				if (this._grid == null) return null;
				return this._grid.hadjustment;
			}
		}

		public Gtk.Adjustment? vadjustment {
			get {
				if (this._grid == null) return null;
				return this._grid.vadjustment;
			}
		}

		public Gtk.Orientation orientation {
			get {
				return this._ori;
			}
			set {
				this._ori = value;
				if (this._grid != null) {
					this._grid.orientation = value;
				}
			}
		}

		construct {
			if (this.max_columns == 0) this.max_columns = 5;
			if (this.min_columns == 0) this.min_columns = 1;
			this._grid = new Gtk.GridView(null, new Gtk.BuilderListItemFactory.from_resource(null, "/com/expidus/genesis/libwidgets/app-grid.glade"));
			this._grid.max_columns = this.max_columns;
			this._grid.min_columns = this.min_columns;
			this._grid.orientation = this._ori;
			this.update_model();

			this.get_style_context().add_class("genesis-app-grid");

			this.child = this._grid;
		}

		private void update_model() {
			if (this._grid != null) {
				Gtk.SelectionModel? model = null;
				switch (this.selection_mode) {
					case AppGridSelectionMode.NONE:
						model = new Gtk.NoSelection(this.model);
						break;
					case AppGridSelectionMode.SINGLE:
						model = new Gtk.SingleSelection(this.model);
						break;
					case AppGridSelectionMode.MULTI:
						model = new Gtk.MultiSelection(this.model);
						break;
				}

				this._grid.set_model(model);
			}
		}
	}

	public class LauncherAppGrid : Bin, Gtk.Orientable, Widget {
		private Gtk.Box _box;
		private AppGrid _grid;
		private Gtk.Scrollbar _scrollbar;
		private uint _max_columns;
		private uint _min_columns;
		private Gtk.Orientation _ori;
		
		public uint max_columns {
			get {
				return this._max_columns;
			}
			set construct {
				this._max_columns = value;
				if (this._grid != null) this._grid.max_columns = value;
			}
		}
		
		public uint min_columns {
			get {
				return this._min_columns;
			}
			set construct {
				this._min_columns = value;
				if (this._grid != null) this._grid.min_columns = value;
			}
		}

		public override Gtk.Orientation orientation {
			get {
				return this._ori;
			}
			set {
				this._ori = value;
				this.update_orientation();
			}
		}

		construct {
			this._box = new Gtk.Box(this._ori, 0);

			this._grid = new AppGrid();
			this._grid.max_columns = this.max_columns;
			this._grid.min_columns = this.min_columns;

			this._grid.model = new LauncherAppModel();

			this._scrollbar = new Gtk.Scrollbar(this._ori, null);

			this._box.append(this._grid);
			this._box.append(this._scrollbar);

			this.child = this._box;

			this.update_orientation();
		}

		private void update_orientation() {
			var inverse_ori = this._ori == Gtk.Orientation.HORIZONTAL ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL;
			if (this._box != null) {
				this._box.orientation = inverse_ori;
			}
			if (this._grid != null) {
				this._grid.orientation = this._ori;
			}
			if (this._scrollbar != null) {
				this._scrollbar.orientation = this._ori;
				this._scrollbar.adjustment = this._ori == Gtk.Orientation.VERTICAL ? this._grid.vadjustment : this._grid.hadjustment;
			}
		}
	}

	public class SettingsAppGrid : Bin, Widget {
		private AppGrid? _grid;
		private uint _max_columns;
		private uint _min_columns;
		private Gtk.Orientation _ori;
		
		public uint max_columns {
			get {
				return this._max_columns;
			}
			set construct {
				this._max_columns = value;
				if (this._grid != null) this._grid.max_columns = value;
			}
		}
		
		public uint min_columns {
			get {
				return this._min_columns;
			}
			set construct {
				this._min_columns = value;
				if (this._grid != null) this._grid.min_columns = value;
			}
		}

		public Gtk.Orientation orientation {
			get {
				return this._ori;
			}
			set construct {
				this._ori = value;
				if (this._grid != null) this._grid.orientation = value;
			}
		}

		construct {
			this._grid = new AppGrid();
			this._grid.max_columns = this.max_columns;
			this._grid.min_columns = this.min_columns;
			this._grid.orientation = this._ori;

			this._grid.model = new SettingsAppModel();

			this.get_style_context().add_class("genesis-app-grid");

			this.child = this._grid;
		}

		public override void size_allocate(int width, int height, int baseline) {
			this._grid.size_allocate(width, height, baseline);
		}

		public override void snapshot(Gtk.Snapshot snapshot) {
			this._grid.snapshot(snapshot);
		}
	}
}