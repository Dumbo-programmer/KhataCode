import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'layout.dart';

class CropResult {
  final Uint8List bytes;
  final bool cornersFound;
  final bool blank;
  const CropResult(this.bytes,
      {required this.cornersFound, required this.blank});
}

CropResult prepareHtmlCapture(Uint8List sourceBytes) {
  final source = img.decodeImage(sourceBytes);
  if (source == null) {
    throw StateError('The captured image could not be decoded.');
  }
  final targetRatio = 210 / 297;
  final sourceRatio = source.width / source.height;
  var cropWidth = source.width;
  var cropHeight = source.height;
  if (sourceRatio > targetRatio) {
    cropWidth = (source.height * targetRatio).round();
  } else {
    cropHeight = (source.width / targetRatio).round();
  }
  final cropped = img.copyCrop(source,
      x: (source.width - cropWidth) ~/ 2,
      y: (source.height - cropHeight) ~/ 2,
      width: cropWidth,
      height: cropHeight);
  final scale = 1600 / cropped.height;
  final resized = scale < 1
      ? img.copyResize(cropped,
          width: (cropped.width * scale).round(), height: 1600)
      : cropped;
  img.grayscale(resized);
  img.contrast(resized, contrast: 150);
  var dark = 0;
  for (final pixel in resized) {
    if (pixel.luminance < 100) {
      dark++;
    }
  }
  final blank = dark < resized.width * resized.height ~/ 200;
  return CropResult(Uint8List.fromList(img.encodePng(resized)),
      cornersFound: false, blank: blank);
}

CropResult prepareCapture(Uint8List sourceBytes) {
  final source = img.decodeImage(sourceBytes);
  if (source == null) {
    throw StateError('The captured image could not be decoded.');
  }
  final scaled = canonicalizeImage(source);
  var dark = 0;
  for (final pixel in scaled) {
    if (pixel.luminance < 100) dark++;
  }
  final blank = dark < scaled.width * scaled.height ~/ 200;
  return CropResult(Uint8List.fromList(img.encodePng(scaled)),
      cornersFound: false, blank: blank);
}
