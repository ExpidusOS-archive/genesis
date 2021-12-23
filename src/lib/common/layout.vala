namespace GenesisCommon {
	/**
		* Layout Type Flags
		*
		* Flags to define what kind of layouts are available
		*/
	[Flags]
	public enum LayoutFlags {
		/**
			* Layout provides window decoration
			*/
		WINDOW_DECORATION,
		/**
			* Layout renders to the desktop
			*/
		DESKTOP,
		/**
			* Layout renders to the panel
			*/
		PANEL,
		/**
			* Layout provides the polkit dialog
			*/
		POLKIT_DIALOG
	}

	/**
		* Window Management Modes
		*/
	public enum LayoutWindowingMode {
		/**
			* Use tiling window management
			*/
		TILING,
		/**
			* Use floating window management
			*/
		FLOATING,
		/**
			* Use "box" window management
			*
			* "Box" layout shows only a signle window maximized at a time
			*/
		BOX
	}

	/**
		* Panel Anchors
		*
		* Anchors will attach the panel to different sides of the monitor
		*/
	[Flags]
	public enum PanelAnchor {
		/**
			* Uses no anchors
			*/
		NONE = 0,
		/**
			* Attach to the left side of the panel
			*/
		LEFT,
		/**
			* Attach to the right side of the panel
			*/
		RIGHT,
		/**
			* Attach to the top side of the panel
			*/
		TOP,
		/**
			* Attach to the bottom side of the panel
			*/
		BOTTOM
	}

	/**
		* The base class for all layout types
		*/
	public abstract class BasicLayout : GLib.Object {
		/**
			* The monitor that this layout exists on
			*/
		public virtual Monitor? monitor {
			owned get {
				return null;
			}
		}

		/**
			* Draws the content of the layout
			*
			* @param cr The Cairo context to render content onto
			*/
		public virtual void draw(Cairo.Context cr) {}

		/**
			* Draws the content of the layout in a specific regiion
			*
			* @param rect The region to draw
			* @return The surface that contains the region which was rendered
			*/
		public virtual Cairo.Surface? draw_region(Gdk.Rectangle rect) {
			return null;
		}

		/**
			* Attaches GTK Widgets
			*
			* @param widget The parent widget to use
			*/
		public virtual void attach(Gtk.Widget widget) {}

		/**
			* Detaches GTK Widgets
			*
			* @param widget The parent widget to use
			*/
		public virtual void detach(Gtk.Widget widget) {}

		/**
			* Signaled when the layout wants to redraw
			*/
		public signal void queue_draw();
	}

	/**
		* Layout type for providing a panel
		*/
	public abstract class PanelLayout : BasicLayout {
		private string _monitor_name;
		private Shell _shell;

		/**
			* The monitor the panel is attached to
			*/
		public override Monitor? monitor {
			owned get {
				return this.shell.find_monitor(this.monitor_name);
			}
		}

		/**
			* The size and position of the panel
			*/
		public abstract Gdk.Rectangle geometry { get; }

		/**
			* The anchor positions of the panel
			*/
		public virtual PanelAnchor anchor {
			get {
				return PanelAnchor.NONE;
			}
		}

		/**
			* Transparency for the panel
			*/
		public virtual bool transparent {
			get {
				return false;
			}
		}

		/**
			* Name of the monitor the panel is attached to
			*/
		public string monitor_name {
			get {
				return this._monitor_name;
			}
			construct {
				this._monitor_name = value;
			}
		}

		/**
			* The shell instance for the monitor
			*/
		public Shell shell {
			get {
				return this._shell;
			}
			construct {
				this._shell = value;
			}
		}
	}

	/**
		* Layout type for the desktop
		*/
	public abstract class DesktopLayout : BasicLayout {
		private string _monitor_name;
		private Shell _shell;

		/**
			* The monitor the desktop is attached to
			*/
		public override Monitor? monitor {
			owned get {
				return this.shell.find_monitor(this.monitor_name);
			}
		}

		/**
			* Name of the monitor the desktop is attached to
			*/
		public string monitor_name {
			get {
				return this._monitor_name;
			}
			construct {
				this._monitor_name = value;
			}
		}

		/**
			* The shell instance for the desktop
			*/
		public Shell shell {
			get {
				return this._shell;
			}
			construct {
				this._shell = value;
			}
		}
	}

	/**
		* A GtkWindow which is used for creating Polkit Dialogs
		*/
	public abstract class PolkitDialog : Gtk.Window {
		/**
			* Polkit Action ID
			*/
		public string action_id { get; construct; }

		/**
			* Polkit message
			*/
		public string message { get; construct; }

		/**
			* Polkit cookie
			*/
		public string cookie { get; construct; }

		/**
			* The cancellable for handling the dialog
			*/
		public GLib.Cancellable? cancellable { get; construct; }

		/**
			* The monitor the dialog is attached to
			*/
		public Monitor monitor { get; construct; }

		/**
			* Boolean to store if the request was cancelled
			*/
		public bool is_cancelled;

		construct {
			this.cancellable.cancelled.connect(this.on_cancelled);
		}

		/**
			* Method to load the Polkit identities
			*
			* @param idents List of identitiess
			*/
		public virtual void set_from_identities(GLib.List<Polkit.Identity> idents) {}

		/**
			* A callback to signal if the authorization was cancelled
			*/
		[GtkCallback]
		public virtual void on_cancelled() {
			this.is_cancelled = true;
			this.done();
		}

		/**
			* Signal to notify the dialog is done
			*/
		public signal void done();
	}

	/**
		* Class for creating layouts
		*/
	public abstract class Layout : GLib.Object {
		private Shell _shell;

		/**
			* Name of the layout
			*/
		public abstract string name { get; }

		/**
			* The monitors the layout should stick to
			*/
		public abstract string[] monitors { owned get; }

		/**
			* The types of layouts this provides
			*/
		public abstract LayoutFlags flags { get; }

		/**
			* Should the layout be tried first?
			*/
		public virtual bool try_first {
			get {
				return false;
			}
		}

		/**
			* Should the layout be tried last?
			*/
		public virtual bool try_last {
			get {
				return false;
			}
		}

		/**
			* The shell instance for the layout
			*/
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
			* @return True if initialized correctly, false if not
			*/
		public bool init(Shell shell) {
			if (this._shell != null) return false;

			this._shell = shell;
			return true;
		}

		/**
			* Gets an instance of ''GenesisCommon.DesktopLayout'' for the monitor
			*
			* @param monitor The monitor to use
			* @return The desktop layout for the monitor
			*/
		public virtual DesktopLayout? get_desktop_layout(Monitor monitor) {
			return null;
		}

		/**
			* Gets a specific panel for the monitor
			*
			* @param monitor The monitor to use
			* @param i The panel number
			* @return The panel for the monitor
			*/
		public virtual PanelLayout? get_panel_layout(Monitor monitor, int i) {
			return null;
		}

		/**
			* Gets the number of panel which exist on the monitor
			*
			* @param monitor The monitor to use
			* @return The number of panels on the monitor
			*/
		public virtual int get_panel_count(Monitor monitor) {
			return 0;
		}

		/**
			* Gets the Polkit dialog for the current Polkit authorization
			*
			* @param monitor The monitor to use
			* @param action_id Polkit Action ID
			* @param message Polkit Message
			* @param icon_name The name of the icon to use
			* @param cookie The Polkit cookie
			* @param cancellable The cancellable to use
			* @return The polkit dialog for the request
			*/
		public virtual PolkitDialog? get_polkit_dialog(Monitor monitor, string action_id, string message, string icon_name, string cookie, GLib.Cancellable? cancellable) {
			return null;
		}
	}
}