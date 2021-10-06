namespace Genesis {
    public errordomain NotificationDaemonError {
        INVALID_ID
    }

    [DBus(name = "com.expidus.GenesisNotifications")]
    public interface NotificationDaemonClient : GLib.Object {
        public abstract uint count { get; }
        public abstract uint32 next_id { get; }
        public abstract uint32 read_count { get; }
        public abstract uint32 unread_count { get; }

        public abstract void @delete(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError;
        public abstract void notify(Notification notif) throws GLib.DBusError, GLib.IOError;
        public abstract bool is_read(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError;
        public abstract void mark_read(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError;
        public abstract void mark_unread(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError;
        public abstract void toggle_read(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError;
        public abstract Notification @get(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError;

        public static NotificationDaemonClient get_default() throws GLib.IOError {
            return GLib.Bus.get_proxy_sync<NotificationDaemonClient>(GLib.BusType.SYSTEM, "com.expidus.GenesisNotifications", "/com/expidus/GenesisNotifications");
        }

        public signal void notified(Notification notif, uint32 id, bool replaced);
        public signal void read(uint32 id);
        public signal void unread(uint32 id);
        public signal void removed(uint32 id);
    }
}