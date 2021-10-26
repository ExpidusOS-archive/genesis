namespace Genesis {
	public class UserIcon : UserBin {
		private Adw.Avatar _avatar;
		private int _size = -1;
		private bool _show_initials;

		public int size {
			get {
				return this._size;
			}
			set construct {
				this._size = value;
				if (this._avatar != null) this._avatar.size = this._size;
			}
		}


		public bool show_initials {
			get {
				return this._show_initials;
			}
			set construct {
				this._show_initials = value;
				if (this._avatar != null) this._avatar.show_initials = this._show_initials;
			}
		}

		construct {
			this._avatar = new Adw.Avatar(this.size, null, this.show_initials);
			this.child = this._avatar;

			this.notify["user"].connect(() => {
				this.load();
			});

			this.load();
		}

		private void load() {
			var user = this.user;
			if (user != null) {
				this._avatar.custom_image = user.icon_file == null ? null : Gtk.MediaFile.for_filename(user.icon_file);
				this._avatar.text = user.real_name == null ? user.user_name : user.real_name;
			} else {
				this._avatar.custom_image = null;
				this._avatar.text = null;
			}
		}
	}
}