[CCode (cprefix = "Gdk", gir_namespace = "GdkWayland", gir_version = "3.0", lower_case_cprefix = "gdk_")]
namespace Gdk {
	namespace Wayland {
		[CCode (cheader_filename = "gdk/gdkwayland.h", type_id = "gdk_wayland_display_get_type ()")]
		[GIR (name = "WaylandDisplay")]
		public class Display : Gdk.Display {
			[CCode (has_construct_function = false)]
			protected Display ();
    }
  }
}
