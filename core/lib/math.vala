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
}