namespace Genesis {
	public enum WindowTypeHint {
		NORMAL,
		PANEL,
		DESKTOP
	}

	public abstract class DisplayWindow : GLib.Object {
		private Gdk.Surface _backend;
		private WindowTypeHint _type;

		public Gdk.Surface backend {
			get {
				return this._backend;
			}
			construct {
				this._backend = value;
			}
		}

		public WindowTypeHint type_hint {
			get {
				return this._type;
			}
			set construct {
				if (this._type != value) {
					this._type = value;
					this.update_type_hint(value);
				}
			}
		}

		public virtual string? dbus_id { owned get; }
		public virtual GLib.MenuModel? menu { owned get; }
		public virtual GLib.ActionGroup? action_group_app { owned get; }
		public virtual GLib.ActionGroup? action_group_win { owned get; }

		public Monitor? monitor {
			owned get {
				return Monitor.from(this.backend.display.get_monitor_at_surface(this.backend));
			}
		}

		public abstract bool skip_pager_hint { get; set; }
		public abstract bool skip_taskbar_hint { get; set; }
		public abstract Gdk.Rectangle geometry { get; set; }

		protected abstract void update_type_hint(WindowTypeHint type);

		public static DisplayWindow? from(Gdk.Surface surf) {
			if (surf == null) return null;

#if BUILD_X11
			if (surf is Gdk.X11.Surface) {
				return new Genesis.X11.DisplayWindow(surf);
			} else
#endif
			{}
			return null;
		}
	}
}