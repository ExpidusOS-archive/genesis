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

        public Act.User? user {
            get {
                return this.username != null ? this._act_mngr.get_user(this.username) : this._act_mngr.get_user_by_id(this.uid);
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
                var user = this.user;
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

    public class UserIconMenu : Gtk.Bin {
        private UserIcon _user_icon;
        private Gtk.Button _btn;
        private Gtk.Menu _menu;

        construct {
            this._menu = new Gtk.Menu();
            this._user_icon = new UserIcon.me();

            this._btn = new Gtk.Button();
            this._btn.add(this._user_icon);
            this._user_icon.show();

            var style_ctx = this._btn.get_style_context();
            style_ctx.remove_class("button");

            this._btn.clicked.connect(() => {
                this._menu.popup_at_widget(this, Gdk.Gravity.CENTER, Gdk.Gravity.CENTER, null);
            });

            this.add(this._btn);
            this._btn.show();

            this._user_icon.notify["user"].connect(() => this.update_menu());
            if (this._user_icon.user != null) this.update_menu();
        }

        public UserIconMenu() {
            Object();
        }

        public override void map() {
            base.map();
            if (this._user_icon.user != null) this.update_menu();
        }

        private void update_menu() {
            this._menu.@foreach((w) => this._menu.remove(w));

            {
                var item = new Gtk.MenuItem.with_label("Log Out");
                item.activate.connect(() => {
                    try {
                        ShellClient shell = GLib.Bus.get_proxy_sync(GLib.BusType.SESSION, "com.expidus.GenesisShell", "/com/expidus/GenesisShell");
                        shell.shutdown();
                    } catch (GLib.Error e) {
                        stderr.printf("Failed to shutdown %s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                    }
                });

                this._menu.append(item);
                item.show();
            }
        }
    }
}