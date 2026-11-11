import 'package:flutter_test/flutter_test.dart';
import 'package:khatacode/layout.dart';

void main() {
  test('maps canonical template coordinates to grid cells', () {
    expect(cellColumn(canonicalGridLeft + canonicalCellWidth / 2), 0);
    expect(cellColumn(canonicalGridLeft + 11.5 * canonicalCellWidth), 11);
    expect(cellRow(canonicalGridTop + canonicalCellHeight / 2), 0);
    expect(cellRow(canonicalGridTop + 15.5 * canonicalCellHeight), 15);
  });

  test('ignores text outside the printed grid', () {
    expect(cellColumn(canonicalGridLeft - 1), isNull);
    expect(cellColumn(canonicalGridLeft + 12 * canonicalCellWidth), isNull);
    expect(cellRow(canonicalGridTop - 1), isNull);
    expect(cellRow(canonicalVariablesBottom), isNull);
  });
}
