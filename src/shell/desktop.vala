namespace Genesis {
    public class Desktop : BaseDesktop {
        public Desktop(Shell shell, string monitor_name) {
            Object(shell: shell, monitor_name: monitor_name);

            this.set_child(new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0));
        }
    }
}