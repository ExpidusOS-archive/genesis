namespace GenesisCommon {
	/**
		* The base class for modules
		*/
	public interface Module : GLib.Object {
		/**
			* Get the shell instance for the module
			*
			* @return The shell instance
			*/
		public abstract Shell get_shell();
	}
}