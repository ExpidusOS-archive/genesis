namespace Genesis {
    [DBus(name = "org.freedesktop.Notifications")]
    public class FreedesktopDaemon {
        private NotificationDaemonServer _server;
        private ulong _removed_id;
        private ulong _action_id;

        public FreedesktopDaemon(NotificationDaemonServer server) {
            this._server = server;

            this._removed_id = this._server.removed.connect((id) => {
                this.notification_closed(id, 4);
            });

            this._action_id = this._server.action.connect((id, key) => {
                this.action_invoked(id, key);
            });
        }

        ~FreedesktopDaemon() {
            this._server.disconnect(this._removed_id);
        }

        [DBus(name = "GetCapabilities")]
        public string[] get_capabilities() throws GLib.DBusError, GLib.IOError {
            return { "actions", "body", "body-hyperlinks" };
        }

        public uint32 notify(string app_name, uint32 replaces_id, string app_icon, string summary, string body, string[] actions, GLib.HashTable<string, GLib.Variant> hints, int32 expires) throws GLib.Error {
            NotificationIcon? icon = null;
            if (app_icon.length > 0) {}

            Notification notif = {
                app_name: app_name,
                replaces: replaces_id,
                summary: summary,
                body: body
            };

            notif.actions = actions;
            notif.icon = icon;
            notif.hints = hints;
            notif.expires = expires;
            return this._server.create_notification(notif);
        }

        [DBus(name = "CloseNotification")]
        public void close_notification(uint32 id) throws GLib.Error {
            this._server.delete(id);
            this.notification_closed(id, 3);
        }

        [DBus(name = "GetServerInformation")]
        public void get_server_information(out string name, out string vendor, out string version, out string spec_version) throws GLib.DBusError, GLib.IOError {
            name = "Genesis Shell Notifications Daemon";
            vendor = "Midstall Software";
            version = VERSION;
            spec_version = "1.2";
        }

        [DBus(name = "NotificationClosed")]
        public signal void notification_closed(uint32 id, uint32 reason);

        [DBus(name = "ActionInvoked")]
        public signal void action_invoked(uint32 id, string key);

        [DBus(name = "ActivationToken")]
        public signal void activation_token(uint32 id, string token);
    }
}