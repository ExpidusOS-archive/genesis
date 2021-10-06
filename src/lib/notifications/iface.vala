namespace Genesis {
    public struct NotificationIcon {
        public int width;
        public int height;
        public int row_stride;
        public bool has_alpha;
        public int bps;
        public int channels;
        public uchar[] data;
    }

    public struct Notification {
        public string? app_name;
        public uint32 replaces;
        public string summary;
        public string? body;
        public string[] actions;
        public NotificationIcon? icon;
        public GLib.HashTable<string, GLib.Variant>? hints;
        public uint expires;
    }
}