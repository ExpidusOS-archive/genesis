namespace Genesis {
    public void init_widgets() {
        typeof (AppButton).name();
        typeof (AppGrid).name();

        typeof (BaseClock).name();
        typeof (BaseWallpaper).name();

        typeof (GlobalMenu).name();
        typeof (GlobalMenuBar).name();

        typeof (LauncherAppGrid).name();
        typeof (Panel).name();

        typeof (SettingsAppGrid).name();
        typeof (SettingsWallpaper).name();

        typeof (SimpleClock).name();

        typeof (UserBin).name();
        typeof (UserButton).name();
        typeof (UserIcon).name();
        typeof (UserMenu).name();
    }

    public static void notify_prop(GLib.Object obj, string name) {
        var type = obj.get_type();
        var cref = type.class_ref();
        unowned var obj_class = (GLib.ObjectClass)cref;

        foreach (var pspec in obj_class.list_properties()) {
            if (pspec.get_name() == name) {
                obj.notify[name](pspec);
                break;
            }
        }
    }
}