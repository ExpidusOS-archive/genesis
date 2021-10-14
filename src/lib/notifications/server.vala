namespace Genesis {
    [DBus(name = "com.expidus.GenesisNotifications")]
    public class NotificationDaemonServer : GLib.Object {
        private GLib.HashTable<uint32, Notification?> _notifs;
        private GLib.List<uint32> _read;
        private uint32 _next_id;

        public uint count {
            get {
                return this._notifs.size();
            }
        }

        public uint32 next_id {
            get {
                return this._next_id;
            }
        }

        public uint32 read_count {
            get {
                return this._read.length();
            }
        }

        public uint32 unread_count {
            get {
                return this._notifs.size() - this._read.length();
            }
        }

        public NotificationDaemonServer() {
            this._notifs = new GLib.HashTable<uint32, Notification?>(GLib.int_hash, GLib.int_equal);
            this._read = new GLib.List<uint32>();
            this._next_id = 1;
        }

        public void delete(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError {
            if (id >= this._next_id || id < 1) throw new NotificationDaemonError.INVALID_ID("ID must be greater than 0 and less than %lu", this._next_id);
            this._notifs.remove(id);
            this.removed(id);
        }

        [DBus(name = "Notify")]
        public uint32 create_notification(Notification notif) throws GLib.DBusError, GLib.IOError {
            var id = notif.replaces == 0 ? this._next_id++ : notif.replaces;
            this._notifs.set(id, notif);
            this.notified(notif, id, notif.replaces != 0);
            return id;
        }

        public bool is_read(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError {
            if (id >= this._next_id || id < 1) throw new NotificationDaemonError.INVALID_ID("ID must be greater than 0 and less than %lu", this._next_id);

            foreach (var n in this._read) {
                if (n == id) return true;
            }
            return false;
        }

        public void mark_read(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError {
            if (id >= this._next_id || id < 1) throw new NotificationDaemonError.INVALID_ID("ID must be greater than 0 and less than %lu", this._next_id);
            if (this.is_read(id)) throw new NotificationDaemonError.INVALID_ID("Notification is already read");

            this._read.append(id);
            this.read(id);
        }

        public void mark_unread(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError {
            if (id >= this._next_id || id < 1) throw new NotificationDaemonError.INVALID_ID("ID must be greater than 0 and less than %lu", this._next_id);
            if (!this.is_read(id)) throw new NotificationDaemonError.INVALID_ID("Notification is already not read");

            this._read.remove(id);
            this.unread(id);
        }

        public void toggle_read(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError {
            if (this.is_read(id)) {
                this.mark_unread(id);
            } else {
                this.mark_read(id);
            }
        }

        [DBus(name = "Get")]
        public Notification @get_notification(uint32 id) throws GLib.DBusError, GLib.IOError, NotificationDaemonError {
            if (id >= this._next_id || id < 1) throw new NotificationDaemonError.INVALID_ID("ID must be greater than 0 and less than %lu", this._next_id);
            return this._notifs.@get(id);
        }

        public signal void notified(Notification notif, uint32 id, bool replaced);
        public signal void action(uint32 id, string key);
        public signal void read(uint32 id);
        public signal void unread(uint32 id);
        public signal void removed(uint32 id);
    }
}