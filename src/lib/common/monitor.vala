namespace GenesisCommon {
	/**
		* Base class for monitors
		*/
	[DBus(name = "com.expidus.genesis.Monitor")]
	public abstract class Monitor : GLib.Object {
		private Shell _shell;

		/**
			* The name of the monitor
			*
			* ''Note'': This may not be the product name of the monitor
			*/
		public abstract string name { owned get; }

		/**
			* The monitor's geometry
			*
			* This holds the monitor's position and resolution
			*/
		[DBus(visible = false)]
		public abstract Gdk.Rectangle geometry { get; }

		/**
			* The physical width of the monitor in millimeters.
			*/
		public abstract int physical_width { get; }

		/**
			* The physical height of the monitor in millimeters.
			*/
		public abstract int physical_height { get; }

		/**
			* The names of the layouts available to this monitor
			*/
		public abstract string[] layout_names { owned get; }

		/**
			* Names of the layouts that should be forced onto this monitor
			*/
		public abstract string[] layout_overrides { owned get; set; }

		/**
			* The shell instance the monitor comes from
			*/
		[DBus(visible = false)]
		public Shell shell {
			get {
				return this._shell;
			}
		}

		/**
			* Similar to ''GLib.Initable.init''
			*
			* This function works similar to ''GLib.Initable.init'' except it takes in a shell instance. ''Never call this method directly.''
			*
			* @param shell The shell instance to use for the monitor
			* @throws GLib.Error The error that occurred while initializing.
			* @return True if initialized correctly, false if not
			*/
		[DBus(visible = false)]
		public virtual bool init(Shell shell) throws GLib.Error {
			if (this._shell != null) return false;

			this._shell = shell;
			return true;
		}

		/**
			* Attaches a layout provided by module from the monitor
			*
			* ''Note'': This method will throw an unsupported method error if this is not overriden.
			*
			* @param module The module which provides layout
			* @param layout The layout that is provided by module
			* @throws ShellError The error that occurred while attaching
			*/
		[DBus(visible = false)]
		public virtual void attach_layout(Module module, Layout layout) throws ShellError {
			throw new ShellError.UNSUPPORTED_METHOD("Cannot attach layout to monitor, method not implemented");
		}

		/**
			* Detaches a layout provided by module from the monitor
			*
			* ''Note'': This method will throw an unsupported method error if this is not overriden.
			*
			* @param module The module which provides layout
			* @param layout The layout that is provided by module
			* @throws ShellError The error that occurred while detaching
			*/
		[DBus(visible = false)]
		public virtual void detach_layout(Module module, Layout layout) throws ShellError {
			throw new ShellError.UNSUPPORTED_METHOD("Cannot attach layout to monitor, method not implemented");
		}

		/**
			* Finds the first layout that provides any of the flags
			*
			* This method relies on the module API in Shell, if your shell instance
			* does not use the module API then no layouts will be found.
			*
			* @param flags The flags to check for
			* @return The layout that provides the flags or null if none found
			*/
		[DBus(visible = false)]
		public virtual Layout? find_layout_provides(LayoutFlags flags) {
			return null;
		}

		/**
			* DBus getter function for retrieving the monitor's geometry
			*
			* @param x The X axis position
			* @param y The Y axis position
			* @param width The width of the monitor's resolution
			* @param height The height of the monitor's resolution
			*/
		[DBus(name = "GetGeometry")]
		public void get_geometry_dbus(out int x, out int y, out int width, out int height) throws GLib.Error {
			x = this.geometry.x;
			y = this.geometry.y;
			width = this.geometry.width;
			height = this.geometry.height;
		}

		/**
			* Gets the physical size of the monitor in millimeters
			*
			* @param width The width of the monitor in millimeters
			* @param height The height of the monitor in millimeters
			*/
		[DBus(visible = false)]
		public virtual void get_physical_size(out int width, out int height) {
			width = height = 0;
		}

		/**
			* Scales ''i'' by the DPI of the monitor
			*
			* This method computes the monitor's DPI and scales it by the DPI.
			* If the DPI cannot be calculated, then it defaults to 96 for the DPI.
			*
			* @param i The value to scale by
			* @return The scaled value in pixels
			*/
		[DBus(visible = false)]
		public int dpi(double i) {
			var diag_inch = GLib.Math.sqrt(GLib.Math.pow(this.physical_width, 2) + GLib.Math.pow(this.physical_height, 2)) * 0.039370;
			var diag_px = GLib.Math.sqrt(GLib.Math.pow(this.geometry.width, 2) + GLib.Math.pow(this.geometry.height, 2));
			var dpi = diag_px / diag_inch;
			if (this.physical_width == 0 || this.physical_height == 0) dpi = 96;
			return (int)((i / 96) * dpi);
		}
		
		public abstract void set_gamma(uint16 size, uint16[] red, uint16[] green, uint16[] blue) throws GLib.Error;
		public abstract void get_gamma(out uint16 size, out uint16[] red, out uint16[] green, out uint16[] blue) throws GLib.Error;

		/**
			* Signaled when a layout is attached to the monitor
			*
			* @param name The name of the layout
			*/
		public signal void layout_attached(string name);

		/**
			* Signaled when a layout is detached from the monitor
			*
			* @param name The name of the layout
			*/
		public signal void layout_detached(string name);

		/**
			* Signaled when a property is updated
			*/
		public signal void updated();

		/**
			* Takes a monitor's name and makes it DBus friendly
			*
			* @param name The name to use
			* @return The DBus friendly name
			*/
		public static string fix_name(string name) {
			return name.down().replace("-", "");
		}
	}

	/**
		* DBus client for the monitor
		*
		* @see Monitor
		*/
	[DBus(name = "com.expidus.genesis.Monitor")]
	public interface MonitorClient : GLib.Object {
		public abstract string name { owned get; }
		public abstract int physical_width { get; }
		public abstract int physical_height { get; }
		public abstract string[] layout_names { owned get; }
		public abstract string[] layout_overrides { owned get; set; }

		public abstract void get_geometry(out int x, out int y, out int width, out int height) throws GLib.Error;
		public abstract void set_gamma(uint16 size, uint16[] red, uint16[] green, uint16[] blue) throws GLib.Error;
		public abstract void get_gamma(out uint16 size, out uint16[] red, out uint16[] green, out uint16[] blue) throws GLib.Error;

		public signal void layout_attached(string name);
		public signal void layout_detached(string name);
		public signal void updated();
	}
}