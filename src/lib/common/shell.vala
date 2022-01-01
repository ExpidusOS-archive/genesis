namespace GenesisCommon {
	/**
		* Types of the Shell instance
		*/
	public enum ShellInstanceType {
		/**
			* No type specified
			*/
		NONE,
		/**
			* Shell instance is on the "window manager" side
			*/
		WM,
		/**
			* Shell instance is the the "component" side
			*/
		COMPONENT
	}

	/**
		* Errors created in the Shell
		*/
	public errordomain ShellError {
		/**
			* A layout that was requested is not valid
			*/
		INVALID_LAYOUT,
		/**
			* A module that was requested is not valid
			*/
		INVALID_MODULE,
		/**
			* A shell instance is not valid
			*/
		INVALID_SHELL,
		/**
			* The method called is not defined, implemented, or valid
			*/
		UNSUPPORTED_METHOD
	}

	/**
		* The Shell itself
		*/
	[DBus(name = "com.expidus.genesis.Shell")]
	public abstract class Shell : GLib.Object, GLib.Initable {
		private DevidentClient.Context _devident;

		/**
			* The devident, Device Identification, client instance
			*/
		[DBus(visible = false)]
		public DevidentClient.Context devident {
			get {
				return this._devident;
			}
		}

		/**
			* Names of the installed modules
			*/
		public abstract string[] modules { owned get; }

		/**
			* Names of the monitors
			*/
		public abstract string[] monitors { owned get; }

		/**
			* Names of layouts provided by modules
			*/
		public abstract string[] layouts { owned get; }

		/**
			* Names of the windows
			*/
		public abstract string[] windows { owned get; }
		
		/**
			* Active window name
			*/
		public abstract string active_window { owned get; }

		/**
			* Type of the shell instance
			*/
		public abstract ShellInstanceType instance_type { get; }

		/**
			* DBus connection that is used
			*/
		[DBus(visible = false)]
		public abstract GLib.DBusConnection? dbus_connection { get; construct; }

		/**
			* Rescans modules and loads any new ones
			*
			* @throws GLib.Error A ''libpeas'' thrown error if failed
			*/
		public abstract void rescan_modules() throws GLib.Error;

		/**
			* Loads a module by its name
			*
			* @param name The name of the module to load
			* @throws GLib.Error A ''libpeas'' thrown error if failed
			* @return True if loaded
			*/
		public abstract bool load_module(string name) throws GLib.Error;

		/**
			* Unloads a module by its name
			*
			* @param name The name of the module to unload
			* @throws GLib.Error A ''libpeas'' thrown error if failed
			* @return True if unloaded
			*/
		public abstract bool unload_module(string name) throws GLib.Error;

		/**
			* Checks if a module exists in this instance, output the name
			*
			* @param module The module to check
			* @param nm The name of the module
			* @return True if the module exists
			*/
		[DBus(visible = false)]
		public abstract bool check_module(Module module, out string? nm);

		/**
			* Gets the plugin information for the module
			*
			* @param module The module to get the information for
			* @return The plugin information or null if not found
			*/
		[DBus(visible = false)]
		public virtual Peas.PluginInfo? get_info_for_module(Module module) {
			return null;
		}

		[DBus(visible = false)]
		public virtual unowned Window? find_window(string key) {
			return null;
		}

		/**
			* Defines a new module layout
			*
			* Layouts are defined per module, this means every module ''must'' define only one layout.
			* In the future, multiple layouts could exist for each layout. Each layout must also use a unique name.
			* If the shell instance does not use modules then this will throw an unsupported method error.
			*
			* @param module The module to use as the owner of the layout
			* @param layout The layout to register
			* @throws ShellError Error if the layout already exists or if the module already has a layout
			*/
		[DBus(visible = false)]
		public virtual void define_layout(Module module, Layout layout) throws ShellError {
			throw new ShellError.UNSUPPORTED_METHOD("This shell instance does not implement \"define_layout\"");
		}

		/**
			* Removes the module's layout
			*
			* If the shell instance does not use modules then this will throw an unsupported method error.
			*
			* @param module The module to use as the owner of the layout
			* @param layout The layout to remove
			* @throws ShellError Error if the layout isn't defined or if the module does not have a layout
			*/
		[DBus(visible = false)]
		public virtual void remove_layout(GenesisCommon.Module module, GenesisCommon.Layout layout) throws ShellError {
			throw new ShellError.UNSUPPORTED_METHOD("This shell instance doe snot implement \"remove_layout\"");
		}

		/**
			* Finds a layout from the name it is defined by
			*
			* @param name The name of the layout
			* @return The layout found or null if not found.
			*/
		[DBus(visible = false)]
		public virtual Layout? get_layout_from_name(string name) {
			return null;
		}

		/**
			* Gets the module that owns the layout
			*
			* @param layout The layout to get its module
			* @return The module of the layout or null if not found
			*/
		[DBus(visible = false)]
		public virtual Module? get_module_for_layout(Layout layout) {
			return null;
		}

		/**
			* Finds a monitor using its name
			*
			* ''Note'': The name of the monitor is not specific between every instance of the shell.
			* The monitor's name may not actually be the product name of the monitor but the backend name.
			*
			* @param name The name of the monitor
			* @return The monitor that was found or null if not found
			*/
		[DBus(visible = false)]
		public abstract unowned Monitor? find_monitor(string name);

		/**
			* Finds a monitor by its x, y position
			*
			* @param x The X position of the monitor
			* @param y The y position of the monitor
			* @return The monitor that was found or null if not found
			*/
		[DBus(visible = false)]
		public unowned Monitor? find_monitor_for_point(int x, int y) {
			var rect = Gdk.Rectangle();
			rect.x = x;
			rect.y = y;
			rect.width = 1;
			rect.height = 1;

			foreach (var monitor_name in this.monitors) {
				unowned var monitor = this.find_monitor(monitor_name);
				if (monitor.geometry.intersect(rect, null)) return monitor;
			}
			return null;
		}

		/**
			* Initializes the shell
			*
			* @see GLib.Initable.init
			*/
		[DBus(visible = false)]
		public virtual bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
			this._devident = (DevidentClient.Context)GLib.Initable.@new(typeof (DevidentClient.Context), cancellable, null);
			return true;
		}

		/**
			* Signaled when the monitor overrides are loaded in
			*
			* @param monitor_name The name of the monitor
			*/
		public signal void monitor_overrides_load(string monitor_name);

		/**
			* Signaled when a monitor is added
			*
			* @param name The name of the monitor
			*/
		public signal void monitor_added(string name);

		/**
			* Signaled when a monitor is removed
			*
			* @param name The name of the monitor
			*/
		public signal void monitor_removed(string name);

		/**
			* Signaled when a layout is added
			*
			* @param name The name of the layout
			*/
		public signal void layout_added(string name);

		/**
			* Signaled when a layout is removed
			*
			* @param name The name of the layout
			*/
		public signal void layout_removed(string name);
		
		/**
			* Signaled when a module is added
			*
			* @param name The name of the module
			*/
		public signal void module_added(string name);

		/**
			* Signaled when a module is removed
			*
			* @param name The name of the module
			*/
		public signal void module_removed(string name);

		/**
			* Signaled when a window is added
			*
			* @param name The name of the window
			*/
		public signal void window_added(string name);

		/**
			* Signaled when a window is removed
			*
			* @param name The name of the window
			*/
		public signal void window_removed(string name);
		
		/**
			* The window focus was changed
			*/
		public signal void window_changed();
	}

	/**
		* DBus client interface for the shell
		*
		* This is the DBus client interface for the shell.
		* @see Shell
		*/
	[DBus(name = "com.expidus.genesis.Shell")]
	public interface ShellClient : GLib.Object {
		public abstract string[] modules { owned get; }
		public abstract string[] monitors { owned get; }
		public abstract string[] layouts { owned get; }
		public abstract string[] windows { owned get; }
		public abstract string active_window { owned get; }

		public abstract void add_monitor(string name, int x, int y, int width, int height) throws GLib.Error;
		public abstract void remove_monitor(string name) throws GLib.Error;

		public abstract void rescan_modules() throws GLib.Error;
		public abstract bool load_module(string name) throws GLib.Error;

		public signal void monitor_added(string name);
		public signal void monitor_removed(string name);

		public signal void layout_added(string name);
		public signal void layout_removed(string name);
		
		public signal void module_added(string name);
		public signal void module_removed(string name);
		
		public signal void window_added(string name);
		public signal void window_removed(string name);
		
		public signal void window_changed();
	}
}