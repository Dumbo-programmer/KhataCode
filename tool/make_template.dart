import 'dart:io';
import 'package:image/image.dart' as img;

const width = 2480;
const height = 3508;
const cell = 40;
const left = 400;
const top = 300;

void main() {
  final dir = Directory('assets/samples')..createSync(recursive: true);
  final template = _sheet();
  File('assets/template.png').writeAsBytesSync(img.encodePng(template));
  File('assets/html_template.png')
      .writeAsBytesSync(img.encodePng(_htmlSheet()));
  _sample(dir, 'valid.png', ['P', '3', '>', 'P', 'a']);
  _sample(dir, 'unclosed_block.png', ['R', '2', '{', 'P', '1']);
  _sample(dir, 'messy.png', ['=', 'a', '4', 'P', 'a'], noisy: true);
  _htmlSample(dir);
}

img.Image _sheet() {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  final paint = img.ColorRgb8(210, 210, 210);
  for (var r = 0; r <= 16; r++) {
    img.drawLine(image,
        x1: left,
        y1: top + r * cell,
        x2: left + 12 * cell,
        y2: top + r * cell,
        color: paint);
  }
  for (var c = 0; c <= 12; c++) {
    img.drawLine(image,
        x1: left + c * cell,
        y1: top,
        x2: left + c * cell,
        y2: top + 16 * cell,
        color: paint);
  }
  for (final p in [
    [left, top],
    [left + 12 * cell, top],
    [left, top + 16 * cell]
  ]) {
    img.drawLine(image,
        x1: p[0],
        y1: p[1],
        x2: p[0] + (p[0] == left ? 35 : -35),
        y2: p[1],
        color: img.ColorRgb8(0, 0, 0),
        thickness: 6);
    img.drawLine(image,
        x1: p[0],
        y1: p[1],
        x2: p[0],
        y2: p[1] + 35,
        color: img.ColorRgb8(0, 0, 0),
        thickness: 6);
  }

  img.drawString(image, 'KhataCode  a  b  c',
      font: img.arial24,
      x: left,
      y: top + 16 * cell + 80,
      color: img.ColorRgb8(0, 0, 0));
  return image;
}

img.Image _htmlSheet() {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  final lineColor = img.ColorRgb8(220, 220, 220);
  for (var y = 520; y < height - 160; y += 142) {
    img.drawLine(image,
        x1: 220, y1: y, x2: width - 220, y2: y, color: lineColor);
  }
  img.drawRect(image,
      x1: 120,
      y1: 120,
      x2: width - 120,
      y2: height - 120,
      color: img.ColorRgb8(80, 80, 80),
      thickness: 4);
  img.drawString(
      image, 'Write one tag or line per ruled line. Print letters large.',
      font: img.arial24, x: 220, y: 250, color: img.ColorRgb8(0, 0, 0));
  return image;
}

void _htmlSample(Directory dir) {
  final image = _htmlSheet();
  const lines = [
    '<h1>Hello</h1>',
    '<p>This is <b>bold</b> text.</p>',
    '<ul><li>One</li><li>Two</li></ul>'
  ];
  for (var i = 0; i < lines.length; i++) {
    img.drawString(image, lines[i],
        font: img.arial48,
        x: 240,
        y: 470 + i * 142,
        color: img.ColorRgb8(0, 0, 0));
  }
  File('${dir.path}/html_valid.png').writeAsBytesSync(img.encodePng(image));
}

void _sample(Directory dir, String name, List<String> glyphs,
    {bool noisy = false}) {
  final image = _sheet();
  for (var i = 0; i < glyphs.length; i++) {
    img.drawString(image, glyphs[i],
        font: img.arial48,
        x: left + i * cell + 8 + (noisy ? (i % 3) * 3 : 0),
        y: top + 5,
        color: img.ColorRgb8(0, 0, 0));
  }
  File('${dir.path}/$name').writeAsBytesSync(img.encodePng(image));
}
