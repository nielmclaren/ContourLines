
int imageWidth;
int imageHeight;
int inputHeight;

float noiseOffset;

PGraphics inputGraphics;
PGraphics outputGraphics;

void setup() {
  size(800, 800, P2D);

  imageWidth = 800;
  imageHeight = 800;
  inputHeight = 128;

  inputGraphics = createGraphics(imageWidth, imageHeight, P2D);
  outputGraphics = createGraphics(imageWidth, imageHeight, P2D);

  reset();
}

void reset() {
  int seedX = 450;
  int seedY = 283;

  noiseOffset = random(10000);

  noiseSeed(0);

  drawInput();

  outputGraphics.beginDraw();
  outputGraphics.background(0);
  outputGraphics.endDraw();
}

void draw() {
  background(0);
  blendMode(ADD);
  image(inputGraphics, 0, 0);
  image(outputGraphics, 0, 0);
}

void drawInput() {
  color c;
  float noiseScale = 0.006;
  float offset = noiseOffset * noiseScale;

  inputGraphics.beginDraw();
  inputGraphics.loadPixels();

  for (int x = 0; x < inputGraphics.width; x++) {
    for (int y = 0; y < inputGraphics.height; y++) {
      inputGraphics.pixels[y * inputGraphics.width + x] = color(255 * noise(x * noiseScale + offset, y * noiseScale + offset));
    }
  }

  FastBlurrer blurrer = new FastBlurrer(imageWidth, imageHeight, 50);
  blurrer.blur(inputGraphics.pixels, 5);

  for (int x = 0; x < inputGraphics.width; x++) {
    for (int y = 0; y < inputGraphics.height; y++) {
      if (brightness(inputGraphics.pixels[y * inputGraphics.width + x]) > inputHeight) {
        c = color(32);
      } else {
        c = color(0);
      }
      inputGraphics.pixels[y * inputGraphics.width + x] = c;
    }
  }

  inputGraphics.updatePixels();
  inputGraphics.endDraw();
}

void drawContourTo(PGraphics pg, int seedX, int seedY) {
  color c = color(0, 128, 0);

  inputGraphics.loadPixels();
  ArrayList<Pixel> pixels = getContourPixels(inputGraphics, seedX, seedY);

  pg.beginDraw();
  pg.loadPixels();

  colorMode(RGB);
  for (int i = 0; i < pixels.size(); i++) {
    Pixel pixel = pixels.get(i);
    pg.pixels[pixel.y * pg.width + pixel.x] = c;
  }

  pg.updatePixels();
  pg.endDraw();
}

ArrayList<Pixel> getContourPixels(PGraphics pg, int seedX, int seedY) {
  ArrayList<Pixel> result = new ArrayList<Pixel>();
  Pixel startPixel = getStartPixel(pg, seedX, seedY);
  if (startPixel == null) {
    return result;
  }

  int dir = 7;
  Pixel pixel = new Pixel(startPixel);
  result.add(startPixel);

  for (int i = 0; i < 100000; i++) {
    int nextDir = getNextPixelDirection(pg, pixel, dir);
    if (nextDir < 0) {
      break;
    }

    Pixel nextPixel = getPixelInDirection(pixel, nextDir);
    if (result.size() > 2 && nextPixel.equals(result.get(2)) && pixel.equals(result.get(1))) {
      break;
    }

    result.add(nextPixel);

    dir = nextDir;
    pixel = nextPixel;
  }
  return result;
}

Pixel getStartPixel(PGraphics pg) {
  return getStartPixel(pg, 0, 0);
}

Pixel getStartPixel(PGraphics pg, int searchStartX, int searchStartY) {
  int b = floor(brightness(pg.pixels[searchStartY * pg.width + searchStartX]));
  for (int y = searchStartY; y < pg.height; y++) {
    for (int x = searchStartX; x < pg.width; x++) {
      if (floor(brightness(pg.pixels[y * pg.width + x])) != b) {
        return new Pixel(x, y);
      }
    }
  }
  return null;
}

int getNextPixelDirection(PGraphics pg, Pixel pixel, int dir) {
  color c = pg.pixels[pixel.y * pg.width + pixel.x];

  if (dir % 2 == 0) {
    dir = (dir + 7) % 8;
  } else {
    dir = (dir + 6) % 8;
  }

  for (int i = 0; i < 8; i++) {
    int nextDir = (dir + i) % 8;
    if (isValidPixel(pg, pixel, nextDir) && c == getColorInDirection(pg, pixel, nextDir)) {
      return nextDir;
    }
  }
  return -1;
}

boolean isValidPixel(PGraphics pg, Pixel pixel, int dir) {
  int x;
  int y;
  switch (dir) {
    case 0:
      x = pixel.x + 1;
      y = pixel.y + 0;
      break;
    case 1:
      x = pixel.x + 1;
      y = pixel.y - 1;
      break;
    case 2:
      x = pixel.x + 0;
      y = pixel.y - 1;
      break;
    case 3:
      x = pixel.x - 1;
      y = pixel.y - 1;
      break;
    case 4:
      x = pixel.x - 1;
      y = pixel.y + 0;
      break;
    case 5:
      x = pixel.x - 1;
      y = pixel.y + 1;
      break;
    case 6:
      x = pixel.x + 0;
      y = pixel.y + 1;
      break;
    case 7:
      x = pixel.x + 1;
      y = pixel.y + 1;
      break;
    default:
      throw new Error("Bad direction. direction=" + dir);
  }
  return x > 0 && x < pg.width && y > 0 && y < pg.height;
}

Pixel getPixelInDirection(Pixel pixel, int dir) {
  int x;
  int y;
  switch (dir) {
    case 0:
      x = pixel.x + 1;
      y = pixel.y + 0;
      break;
    case 1:
      x = pixel.x + 1;
      y = pixel.y - 1;
      break;
    case 2:
      x = pixel.x + 0;
      y = pixel.y - 1;
      break;
    case 3:
      x = pixel.x - 1;
      y = pixel.y - 1;
      break;
    case 4:
      x = pixel.x - 1;
      y = pixel.y + 0;
      break;
    case 5:
      x = pixel.x - 1;
      y = pixel.y + 1;
      break;
    case 6:
      x = pixel.x + 0;
      y = pixel.y + 1;
      break;
    case 7:
      x = pixel.x + 1;
      y = pixel.y + 1;
      break;
    default:
      throw new Error("Bad direction. direction=" + dir);
  }
  return new Pixel(x, y);
}

color getColorInDirection(PGraphics pg, Pixel pixel, int dir) {
  int x;
  int y;
  switch (dir) {
    case 0:
      x = pixel.x + 1;
      y = pixel.y + 0;
      break;
    case 1:
      x = pixel.x + 1;
      y = pixel.y - 1;
      break;
    case 2:
      x = pixel.x + 0;
      y = pixel.y - 1;
      break;
    case 3:
      x = pixel.x - 1;
      y = pixel.y - 1;
      break;
    case 4:
      x = pixel.x - 1;
      y = pixel.y + 0;
      break;
    case 5:
      x = pixel.x - 1;
      y = pixel.y + 1;
      break;
    case 6:
      x = pixel.x + 0;
      y = pixel.y + 1;
      break;
    case 7:
      x = pixel.x + 1;
      y = pixel.y + 1;
      break;
    default:
      throw new Error("Bad direction. direction=" + dir);
  }
  return pg.pixels[y * pg.width + x];
}

void keyReleased() {
  switch (key) {
    case 'e':
      reset();
      break;

    case 'j':
      inputHeight += 8;
      drawInput();
      break;
    case 'k':
      inputHeight -= 8;
      drawInput();
      break;

    case 'r':
      save("render.png");
      break;
  }
}

void mouseReleased() {
  drawContourTo(outputGraphics, mouseX, mouseY);
}


