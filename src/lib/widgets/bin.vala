namespace Genesis {
	public class Bin : Gtk.Widget, Gtk.Buildable, Widget {
		private Gtk.Widget? _child;

		public Gtk.Widget? child {
			get {
				return this._child;
			}
			set construct {
				if (this._child != null) this._child.unparent();
				this._child = value;
				if (this._child != null) this._child.set_parent(this);
				this.queue_allocate();
				this.queue_resize();
				this.queue_draw();
			}
		}

		class construct {
			set_layout_manager_type(typeof (Gtk.BinLayout));
		}

		public void add_child(Gtk.Builder builder, GLib.Object _child, string? type)  {
			var child = _child as Gtk.Widget;
			if (child != null) this.child = child;
			else base.add_child(builder, _child, type);
		}

		public override void compute_expand_internal(out bool hexpand, out bool vexpand) {
			hexpand = false;
			vexpand = false;

			Gtk.Widget? child = null;
			for (child = this.get_first_child(); child != null; child = child.get_next_sibling()) {
				hexpand = hexpand || child.compute_expand(Gtk.Orientation.HORIZONTAL);
				vexpand = vexpand || child.compute_expand(Gtk.Orientation.VERTICAL);
			}
		}

		public override void measure(Gtk.Orientation ori, int for_size, out int min, out int nat, out int min_base, out int nat_base) {
			min = nat = 0;
			min_base = nat_base = -1;
			if (this._child != null) {
				this._child.measure(ori, for_size, out min, out nat, out min_base, out nat_base);
			}
		}

		public override void size_allocate(int width, int height, int baseline) {
			if (this._child != null) this._child.size_allocate(width, height, baseline);
		}

		public override void snapshot(Gtk.Snapshot snapshot) {
			if (this._child != null) {
				this._child.snapshot(snapshot);
			}
		}
	}
}