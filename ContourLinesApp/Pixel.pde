
class Pixel {
  int x;
  int y;

  Pixel() {
    x = 0;
    y = 0;
  }

  Pixel(int xArg, int yArg) {
    x = xArg;
    y = yArg;
  }

  Pixel(Pixel v) {
    x = v.x;
    y = v.y;
  }

  boolean equals(Pixel v) {
    return x == v.x && y == v.y;
  }

  String toString() {
    return "Pixel(" + x + ", " + y + ")";
  }
}
