namespace Genesis {
	public class GlobalMenuBar : Bin {
		private GlobalMenu _global_menu;
		private Gtk.PopoverMenuBar _menu_bar;
		private ulong _active_win_id;

		construct {
			this._global_menu = new GlobalMenu();
			this._menu_bar = new Gtk.PopoverMenuBar.from_model(this._global_menu);
			this._menu_bar.insert_action_group("app", this._global_menu);
			this.child = this._menu_bar;
		}

		public override void map() {
			base.map();

			this._active_win_id = this.get_display().notify["active_window"].connect(() => {
				this.sync();
			});

			this.sync();
		}

		public override void unmap() {
			this.get_display().disconnect(this._active_win_id);
			base.unmap();
		}

		private void sync() {
			if (this.get_mapped()) {
				this._global_menu.sync(this.get_display());
			}
		}
	}
}