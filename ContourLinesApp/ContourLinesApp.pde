
int imageWidth;
int imageHeight;
int zoomScale;

PGraphics inputGraphics;
PGraphics outputGraphics;
PGraphics zoomGraphics;

void setup() {
  size(1600, 800, P2D);
  noSmooth();

  imageWidth = 800;
  imageHeight = 800;
  zoomScale = 80;

  inputGraphics = createGraphics(imageWidth, imageHeight, P2D);
  outputGraphics = createGraphics(imageWidth, imageHeight, P2D);
  zoomGraphics = createGraphics(imageWidth, imageHeight, P2D);

  reset();
}

void reset() {
  int seedX = 450;
  int seedY = 283;

  noiseSeed(0);

  drawInput(inputGraphics);

  outputGraphics.beginDraw();
  outputGraphics.background(0);
  outputGraphics.endDraw();
  drawContourTo(outputGraphics, seedX, seedY);

  Pixel startPixel = getStartPixel(inputGraphics, seedX, seedY);
  if (startPixel != null) {
    g.loadPixels();
    zoomGraphics.loadPixels();
    drawZoomedTo(zoomGraphics, startPixel.x - 3, startPixel.y - 3);
    zoomGraphics.updatePixels();
    g.updatePixels();
    zoomGraphics.updatePixels();
  }
}

void draw() {
  background(0);
  blendMode(ADD);
  image(inputGraphics, 0, 0);
  image(outputGraphics, 0, 0);
  blendMode(BLEND);
  image(zoomGraphics, imageWidth, 0);
}

void drawInput(PGraphics pg) {
  color c;
  float noiseScale = 0.006;
  float offset = random(10000) * noiseScale;

  pg.beginDraw();
  pg.loadPixels();

  for (int x = 0; x < pg.width; x++) {
    for (int y = 0; y < pg.height; y++) {
      pg.pixels[y * pg.width + x] = color(255 * noise(x * noiseScale + offset, y * noiseScale + offset));
    }
  }

  FastBlurrer blurrer = new FastBlurrer(imageWidth, imageHeight, 5);
  blurrer.blur(pg.pixels);

  for (int x = 0; x < pg.width; x++) {
    for (int y = 0; y < pg.height; y++) {
      if (brightness(pg.pixels[y * pg.width + x]) > 128) {
        c = color(32);
      } else {
        c = color(0);
      }
      pg.pixels[y * pg.width + x] = c;
    }
  }

  pg.updatePixels();
  pg.endDraw();
}

void drawContourTo(PGraphics pg, int seedX, int seedY) {
  color c = color(64);

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
  println("Add", pixel);
  result.add(startPixel);
  println("Seed pixel:", seedX, seedY);
  println("Start pixel:", startPixel);

  for (int i = 0; i < 100000; i++) {
    int nextDir = getNextPixelDirection(pg, pixel, dir);
    if (nextDir < 0) {
      break;
    }

    Pixel nextPixel = getPixelInDirection(pixel, nextDir);
    if (result.size() > 2 && nextPixel.equals(result.get(2)) && pixel.equals(result.get(1))) {
      println("### BREAK ###", result.size());
      break;
    }

    println("Add", nextPixel);
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
  println("Search start:", searchStartX, searchStartY);
  int b = floor(brightness(pg.pixels[searchStartY * pg.width + searchStartX]));
  for (int y = searchStartY; y < pg.height; y++) {
    for (int x = searchStartX; x < pg.width; x++) {
      if (floor(brightness(pg.pixels[y * pg.width + x])) != b) {
        println("Search result:", x, y);
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

void drawZoomedTo(PGraphics targetGraphics, int sourceX, int sourceY) {
  colorMode(RGB);
  for (int x = 0; x < targetGraphics.width / zoomScale; x++) {
    for (int y = 0; y < targetGraphics.height / zoomScale; y++) {
      color inputColor = inputGraphics.pixels[(sourceY + y) * inputGraphics.width + (sourceX + x)];
      color outputColor = outputGraphics.pixels[(sourceY + y) * outputGraphics.width + (sourceX + x)];

      for (int outputX = 0; outputX < zoomScale; outputX++) {
        for (int outputY = 0; outputY < zoomScale; outputY++) {
          if ((x * zoomScale + outputX) % zoomScale == 0 || (y * zoomScale + outputY) % zoomScale == 0) {
            targetGraphics.pixels[(y * zoomScale + outputY) * targetGraphics.width + (x * zoomScale + outputX)] = color(255);
          } else if (outputX > zoomScale * 0.25 && outputX < zoomScale * 0.75 && outputY > zoomScale * 0.25 && outputY < zoomScale * 0.75) {
            targetGraphics.pixels[(y * zoomScale + outputY) * targetGraphics.width + (x * zoomScale + outputX)] = outputColor;
          } else {
            targetGraphics.pixels[(y * zoomScale + outputY) * targetGraphics.width + (x * zoomScale + outputX)] = inputColor;
          }
        }
      }
    }
  }
}

void keyReleased() {
  switch (key) {
    case 'e':
      reset();
      break;
    case 'r':
      save("render.png");
      break;
  }
}

void mouseReleased() {
  outputGraphics.beginDraw();
  outputGraphics.noFill();
  outputGraphics.stroke(0, 255, 0);
  outputGraphics.ellipse(mouseX, mouseY, 5, 5);
  outputGraphics.endDraw();

  drawContourTo(outputGraphics, mouseX, mouseY);

  Pixel startPixel = getStartPixel(inputGraphics, mouseX, mouseY);
  if (startPixel != null) {
    g.loadPixels();
    zoomGraphics.loadPixels();
    drawZoomedTo(zoomGraphics, startPixel.x - 3, startPixel.y - 3);
    zoomGraphics.updatePixels();
    g.updatePixels();
    zoomGraphics.updatePixels();
  }
}


