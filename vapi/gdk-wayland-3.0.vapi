[CCode (cprefix = "GdkWayland", gir_namespace = "GdkWayland", gir_version = "3.0", lower_case_cprefix = "gdk_wayland_")]
namespace Gdk.Wayland {
	[CCode (cheader_filename = "gdk/gdkwayland.h", type_id = "gdk_wayland_device_get_type ()")]
	public class Device : Gdk.Device {
		[CCode (has_construct_function = false)]
		protected Device();
	}
	[CCode (cheader_filename = "gdk/gdkwayland.h", type_id = "gdk_wayland_display_get_type ()")]
	public class Display : Gdk.Display {
		[CCode (has_construct_function = false)]
		protected Display();
	}
	[CCode (cheader_filename = "gdk/gdkwayland.h", type_id = "gdk_wayland_gl_context_get_type ()")]
	public class GLContext : Gdk.GLContext {
		[CCode (has_construct_function = false)]
		protected GLContext();
	}
	[CCode (cheader_filename = "gdk/gdkwayland.h", type_id = "gdk_wayland_monitor_get_type ()")]
	public class Monitor : Gdk.Monitor {
		[CCode (has_construct_function = false)]
		protected Monitor();
	}
	[CCode (cheader_filename = "gdk/gdkwayland.h", type_id = "gdk_wayland_window_get_type ()")]
	public class Window : Gdk.Window {
		[CCode (has_construct_function = false)]
		protected Window();
	}
}
