namespace Genesis {
    public class UserIcon : Gtk.Bin {
        private Hdy.Avatar _avatar;
        private Act.UserManager _act_mngr;

        private ulong _act_mngr_load;
        private ulong _act_mngr_changed;

        private string? _username = null;
        private uint _uid = 0;
        private int _size;
        private bool _show_int = false;

        public string? username {
            get {
                return this._username;
            }
            set construct {
                this._username = value;
                this._uid = 0;
                if (this._avatar != null && this._act_mngr != null) this.update();
            }
        }

        public uint uid {
            get {
                return this._uid;
            }
            set construct {
                this._username = null;
                this._uid = value;
                if (this._avatar != null && this._act_mngr != null) this.update();
            }
        }

        public int size {
            get {
                if (this._avatar != null) return this._avatar.size;
                return this._size;
            }
            set construct {
                this._size = value;
                if (this._avatar != null) {
                    this._avatar.size = value;
                }
            }
        }

        public bool show_int {
            get {
                if (this._avatar != null) return this._avatar.show_initials;
                return this._show_int;
            }
            set construct {
                this._show_int = value;
                if (this._avatar != null) {
                    this._avatar.show_initials = value;
                }
            }
        }

        construct {
            if (this.size == 0) {
                this.size = 32;
            }

            if (this._uid == -1) {
                this._uid = (uint)Posix.geteuid();
            }

            this._avatar = new Hdy.Avatar(this.size, null, false);
            this.add(this._avatar);
            this._avatar.show();

            this._act_mngr = Act.UserManager.get_default();
            if (this._act_mngr.is_loaded) this.update();
            else {
                this._act_mngr_load = this._act_mngr.notify["is-loaded"].connect(() => {
                    this.update();
                    this._act_mngr.disconnect(this._act_mngr_load);
                    this._act_mngr_load = 0;
                });
            }

            this._act_mngr_changed = this._act_mngr.user_changed.connect((user) => {
                if (this._uid == user.uid || this.username == user.user_name) {
                    this.update();
                }
            });
        }

        public UserIcon(string username) {
            Object(username: username);
        }

        public UserIcon.with_id(uint uid) {
            Object(uid: uid);
        }

        public UserIcon.me() {
            Object(uid: -1);
        }

        ~UserIcon() {
            if (this._act_mngr_load > 0) {
                this._act_mngr.disconnect(this._act_mngr_load);
            }

            this._act_mngr.disconnect(this._act_mngr_changed);
        }

        private void update() {
            var tries = 0;
            GLib.Timeout.add(200, () => {
                tries++;
                var user = this.username != null ? this._act_mngr.get_user(this.username) : this._act_mngr.get_user_by_id(this.uid);
                if (user == null) {
                    stderr.printf("Failed to load user %s\n", this.username != null ? this.username : this.uid.to_string());
                } else {
                    if (user.icon_file != null && user.icon_file.length > 0) {
                        this._avatar.loadable_icon = new GLib.FileIcon(GLib.File.new_for_path(user.icon_file));
                    } else {
                        if (tries < 3) {
                            this.update();
                            return false;
                        }
                    }

                    if (user.real_name != null && user.real_name.length > 0) {
                        this._avatar.text = user.real_name;
                    } else {
                        this._avatar.text = user.user_name;
                    }
                }
                return false;
            });
        }
    }
}