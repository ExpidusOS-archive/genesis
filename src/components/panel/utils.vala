namespace Genesis {
    public static double get_monitor_dpi(int width_px, int height_px, int width_mm, int height_mm) {
        var diag_inch = GLib.Math.sqrt(GLib.Math.pow(width_mm, 2) + GLib.Math.pow(height_mm, 2)) * 0.039370;
        var diag_px = GLib.Math.sqrt(GLib.Math.pow(width_px, 2) + GLib.Math.pow(height_px, 2));
        return diag_px / diag_inch;
    }

    public static double compute_dpi(double dpi, int size, double scale = 1.0) {
        var r = (size * dpi) / 96;
        if (r == 0) r = 96.0;
        return r * scale;
    }
}