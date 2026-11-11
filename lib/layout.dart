import 'dart:math' as math;
import 'package:image/image.dart' as img;

const int columns = 12;
const int rows = 17;
const double cellMm = 4;
const double a4WidthMm = 210;
const double a4HeightMm = 297;
const double canonicalWidth = 1000;
const double templateWidth = 2480;
const double templateGridLeft = 400;
const double templateGridTop = 300;
const double templateCell = 40;
const double canonicalGridLeft = canonicalWidth * templateGridLeft / templateWidth;
const double canonicalGridTop = canonicalWidth * templateGridTop / templateWidth;
const double canonicalCellWidth = canonicalWidth * templateCell / templateWidth;
const double canonicalCellHeight = canonicalCellWidth;
const double canonicalGridBottom = canonicalGridTop + 16 * canonicalCellHeight;
const double canonicalVariablesBottom = canonicalGridBottom + 120 * canonicalWidth / templateWidth;

class LayoutPoint {
  final double x;
  final double y;
  const LayoutPoint(this.x, this.y);
}

const LayoutPoint topLeftMark = LayoutPoint(18, 18);
const LayoutPoint topRightMark = LayoutPoint(canonicalWidth - 18, 18);
const LayoutPoint bottomLeftMark =
    LayoutPoint(18, 16 * canonicalCellHeight - 18);

int? cellColumn(double x) {
  if (x < canonicalGridLeft ||
      x >= canonicalGridLeft + columns * canonicalCellWidth) {
    return null;
  }
  return ((x - canonicalGridLeft) / canonicalCellWidth).floor();
}

int? cellRow(double y) {
  if (y >= canonicalGridTop && y < canonicalGridBottom) {
    return ((y - canonicalGridTop) / canonicalCellHeight).floor();
  }
  if (y >= canonicalGridBottom && y < canonicalVariablesBottom) {
    return 16;
  }
  return null;
}

img.Image canonicalizeImage(img.Image source) {
  final scale = canonicalWidth / source.width;
  return img.copyResize(source,
      width: canonicalWidth.toInt(), height: (source.height * scale).round());
}

double markDistance(LayoutPoint a, LayoutPoint b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
