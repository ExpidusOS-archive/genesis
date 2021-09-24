namespace Genesis {
    public class MetaPlugin : Meta.Plugin {
        private Shell _shell;
        private Lua.LuaVM _lvm;
        private Meta.PluginInfo _plugin_info;
        private Meta.MonitorManager _monitor_mngr;
        private Meta.BackgroundGroup _bg_group;
        private SystemRT.SystemRT _systemrt;

        construct {
            this._plugin_info = Meta.PluginInfo() {
                name = "Genesis Shell",
                version = Genesis.VERSION,
                author = "Midstall Software",
                license = "GPL-3.0",
                description = "The next generation computing environment"
            };
            
            try {
                this._systemrt = GLib.Bus.get_proxy_sync(GLib.BusType.SYSTEM, "com.expidus.SystemRT", "/com/expidus/SystemRT");
                this._shell = new Shell();

                this._shell.dead.connect(() => {
                    Meta.exit(Meta.ExitCode.SUCCESS);
                });
            } catch (GLib.Error e) {
                stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                Meta.exit(Meta.ExitCode.ERROR);
            }

            this._lvm = new Lua.LuaVM.with_alloc_func((ptr, osize, nsize) => {
                if (nsize == 0) {
                    GLib.free(ptr);
                    return null;
                }

                return GLib.realloc(ptr, nsize);
            });

            this._lvm.open_libs();

            this._shell.to_lua(this._lvm);

            this._lvm.push_string("wm");
            this._lvm.push_lightuserdata(this);
            this._lvm.raw_set(-3);

            this._lvm.set_global("genesis");
        }

        public override unowned Meta.PluginInfo? plugin_info() {
            return this._plugin_info;
        }

        public override void start() {
            try {
                this._systemrt.own_session(GLib.Environment.get_variable("DISPLAY"), GLib.Environment.get_variable("XAUTHORITY"));

                var dir = GLib.Dir.open(Genesis.DATADIR + "/genesis/misd");
                string? name;

                while ((name = dir.read_name()) != null) {
                    var path = Genesis.DATADIR + "/genesis/misd/%s".printf(name);
                    if (!GLib.FileUtils.test(path, GLib.FileTest.IS_REGULAR)) continue;

                    if (this._lvm.do_file(path)) {
                        stderr.printf("genesis-shell: failed to load \"%s\": %s\n", path, this._lvm.to_string(-1));
                    }
                }
            } catch (GLib.Error e) {
                stderr.printf("%s (%d): %s\n", e.domain.to_string(), e.code, e.message);
                Meta.exit(Meta.ExitCode.ERROR);
            }

            this._monitor_mngr = Meta.MonitorManager.@get();
            this._bg_group = new Meta.BackgroundGroup();
            
            Meta.Compositor.get_window_group_for_display(this.get_display()).insert_child_below(this._bg_group, null);

            this._monitor_mngr.monitors_changed.connect(() => {
                var n_monitors = this.get_display().get_n_monitors();

                string[] monitors = {};
                for (var i = 0; i < n_monitors; i++) monitors += i.to_string();

                foreach (var m in this._shell.monitors) {
                    if (!(m in monitors)) {
                        this._shell.monitor_load(m);
                    }
                }
                
                foreach (var m in monitors) {
                    if (!(m in this._shell.monitors)) {
                        this._shell.monitor_unload(m);
                    }
                }

                this._bg_group.destroy_all_children();

                for (var i = 0; i < n_monitors; i++) {
                    var rect = this.get_display().get_monitor_geometry(i);

                    var bg_actor = new Meta.BackgroundActor(this.get_display(), i);
                    var content = bg_actor.get_content() as Meta.BackgroundContent;
                    assert(content != null);

                    bg_actor.set_position(rect.x, rect.y);
                    bg_actor.set_size(rect.width, rect.height);

                    var color = Clutter.Color.alloc();
                    color.init(0, 0, 0, 255);

                    var bg = new Meta.Background(this.get_display());
                    bg.set_color(color);
                    content.set_background(bg);

                    this._bg_group.add_child(bg_actor);
                }
            });

            var n_monitors = this.get_display().get_n_monitors();

            string[] monitors = {};
            for (var i = 0; i < n_monitors; i++) monitors += i.to_string();

            this._shell.load(monitors);

            Meta.Compositor.get_stage_for_display(this.get_display()).show();
        }

        public override void map(Meta.WindowActor actor) {
            this.map_completed(actor);
        }
    }
}