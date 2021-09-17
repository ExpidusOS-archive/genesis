namespace Genesis {
    public class Desktop : BaseDesktop {
        private Gtk.Image _background;

        public Desktop(Shell shell, string monitor_name) {
            Object(shell: shell, monitor_name: monitor_name);

            this._background = new Gtk.Image.from_file("/usr/share/wallpaper/default.png");
            this.add(this._background);
        }
    }
}