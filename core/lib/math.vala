namespace GenesisShell {
  [DBus(name = "com.expidus.genesis.Box")]
  public struct Box {
    public int top;
    public int bottom;
    public int left;
    public int right;
  }

  [DBus(name = "com.expidus.genesis.Rectangle")]
  public struct Rectangle {
    public int x;
    public int y;
    public int width;
    public int height;
  }

  namespace Math {
    public static int round(int num) {
      while ((num % 10) > 0) num++;
      return num;
    }

    public static int em(double dpi, double size) {
      return round((int)((dpi * size) / 5.5));
    }
  }
}
