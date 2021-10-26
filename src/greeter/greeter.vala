namespace Genesis {
	public class Greeter : Gtk.Application {
    public Greeter() {
	    Object(application_id: "com.expidus.GenesisGreeter");
	    this.set_option_context_parameter_string(_("- Genesis Shell Greeter for LightDM"));
		}

  	public override void activate() {
			new GLib.MainLoop().run();
		}
	}

	public static int main(string[] argv) {
		GLib.Intl.setlocale(GLib.LocaleCategory.ALL, ""); 
	  GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, DATADIR + "/locale");
	  GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
	  GLib.Intl.textdomain(GETTEXT_PACKAGE);

	  GLib.Environment.set_application_name(GETTEXT_PACKAGE);
	  GLib.Environment.set_prgname(GETTEXT_PACKAGE);
		return new Greeter().run(argv);
	}
}

[CCode(cheader_filename="build.h")]
extern const string GETTEXT_PACKAGE;