import 'dart:math' as math;
import 'package:image/image.dart' as img;

const int columns = 12;
const int rows = 17;
const double cellMm = 4;
const double a4WidthMm = 210;
const double a4HeightMm = 297;
const double canonicalWidth = 1000;
const double canonicalGridHeight = 16 * 4;
const double canonicalCellWidth = canonicalWidth / columns;
const double canonicalCellHeight = canonicalWidth / (a4WidthMm / cellMm);

class LayoutPoint {
  final double x;
  final double y;
  const LayoutPoint(this.x, this.y);
}

const LayoutPoint topLeftMark = LayoutPoint(18, 18);
const LayoutPoint topRightMark = LayoutPoint(canonicalWidth - 18, 18);
const LayoutPoint bottomLeftMark =
    LayoutPoint(18, 16 * canonicalCellHeight - 18);

int cellColumn(double x) =>
    (x / canonicalCellWidth).floor().clamp(0, columns - 1).toInt();
int cellRow(double y) =>
    (y / canonicalCellHeight).floor().clamp(0, rows - 1).toInt();

img.Image canonicalizeImage(img.Image source) {
  final scale = canonicalWidth / source.width;
  return img.copyResize(source,
      width: canonicalWidth.toInt(), height: (source.height * scale).round());
}

double markDistance(LayoutPoint a, LayoutPoint b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
