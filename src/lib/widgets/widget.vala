namespace Genesis {
	public interface Widget : Gtk.Widget {
		public new Display? get_display() {
			var disp = ((Gtk.Widget)this).get_display();
			if (disp == null) return null;
			return Genesis.Display.from(disp);
		}

		public double compute_size(int size) {
			var win = this.get_window();
			if (win == null) return 0.0;

			var monitor = win.monitor;
			if (monitor == null) return 0.0;

			var r = (size * monitor.dpi) / 96;
			if (r == 0) r = 96.0;
			return r * this.scale_factor;
		}

		public Gtk.Widget? get_toplevel() {
			var curr = this.parent;
			while (curr != null) {
				if (curr.parent == null) return curr;
				curr = curr.parent;
			}
			return null;
		}

		public DisplayWindow? get_window() {
			return Genesis.DisplayWindow.from(this.get_root().get_surface());
		}

		public void to_lua(Lua.LuaVM lvm) {
			lvm.new_table();

			lvm.push_string("_native");
			lvm.push_lightuserdata(this);
			lvm.raw_set(-3);

			lvm.push_string("get_children");
			lvm.push_cfunction((lvm) => {
				if (lvm.get_top() != 1) {
					lvm.push_literal("Invalid argument count");
					lvm.error();
					return 0;
				}

				if (lvm.type(1) != Lua.Type.TABLE) {
					lvm.push_literal("Invalid argument #1: expected a table");
					lvm.error();
					return 0;
				}

				lvm.get_field(1, "_native");
				var self = (Genesis.Widget)lvm.to_userdata(2);

				var children = self.observe_children();
				lvm.new_table();
				for (var i = 0; i < children.get_n_items(); i++) {
					var _child = children.get_item(i) as Gtk.Widget;
					if (_child == null) continue;

					var child = (Genesis.Widget)_child;
					lvm.push_number(i + 1);
					child.to_lua(lvm);
					lvm.set_table(3);
				}
				return 1;
			});

			lvm.push_string("get_parent");
			lvm.push_cfunction((lvm) => {
				if (lvm.get_top() != 1) {
					lvm.push_literal("Invalid argument count");
					lvm.error();
					return 0;
				}

				if (lvm.type(1) != Lua.Type.TABLE) {
					lvm.push_literal("Invalid argument #1: expected a table");
					lvm.error();
					return 0;
				}

				lvm.get_field(1, "_native");
				var self = (Genesis.Widget)lvm.to_userdata(2);

				var parent = (Genesis.Widget)self.get_parent();
				if (parent != null) {
					parent.to_lua(lvm);
				} else {
					lvm.push_nil();
				}
				return 1;
			});
		}
	}
}