namespace Genesis {
	public class UserBin : Bin {
		private string? _username;
		private int _uid;
		private Act.User? _user;
		private ulong _changed_id;

		public string? username {
			get {
				return this._username;
			}
			set construct {
				if (this._user != null && this._changed_id > 0) {
					this._user.disconnect(this._changed_id);
					this._changed_id = 0;
				}

				this._username = value;
				this._uid = -1;
				this._user = null;

				notify_prop(this, "uid");
				notify_prop(this, "user");
			}
		}

		public int uid {
			get {
				return this._uid;
			}
			set construct {
				if (this._user != null && this._changed_id > 0) {
					this._user.disconnect(this._changed_id);
					this._changed_id = 0;
				}

				this._username = null;
				this._uid = value;
				this._user = null;

				notify_prop(this, "username");
				notify_prop(this, "user");
			}
		}

		public Act.User? user {
			get {
				var act_mngr = Act.UserManager.get_default();
				if (this._user == null) {
					if (this._username != null) this._user = act_mngr.get_user(this._username);
					else if (this._uid > -1) this._user = act_mngr.get_user_by_id(this._uid);

					if (this._user == null && !act_mngr.is_loaded) {
						ulong id = 0;
						
						id = act_mngr.notify["is-loaded"].connect(() => {
							if (id > 0) {
								act_mngr.disconnect(id);
								id = 0;
							}
							notify_prop(this, "user");
						});
					}

					if (this._user != null && this._changed_id == 0) {
						this._changed_id = this._user.changed.connect(() => {
							notify_prop(this, "user");
						});
					}
					return this._user;
				}
				return this._user;
			}
			set construct {
				if (this._user != null && this._changed_id > 0) {
					this._user.disconnect(this._changed_id);
					this._changed_id = 0;
				}

				this._username = null;
				this._uid = -1;
				this._user = value;

				if (this._user != null && this._changed_id == 0) {
					this._changed_id = this._user.changed.connect(() => {
						notify_prop(this, "user");
					});
				}

				notify_prop(this, "uid");
				notify_prop(this, "username");
			}
		}

		construct {
			if (this.user == null) this.uid = (int)Posix.geteuid();
		}
	}
}