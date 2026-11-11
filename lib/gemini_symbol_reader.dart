import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiSymbolReader {
  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  bool get isConfigured => apiKey.isNotEmpty;

  Future<List<List<String?>>> read(Uint8List imageBytes) async {
    if (!isConfigured) {
      throw StateError(
          'Gemini is not configured. Start the app with '
          '--dart-define=GEMINI_API_KEY=your-key.');
    }

    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0,
        responseMimeType: 'application/json',
      ),
    );
    final response = await model.generateContent([
      Content.multi([
        TextPart('''
Read the KhataCode symbol sheet in this image. First locate the printed
12-column by 16-row program grid. The grid begins below the top registration
marks and ends above the printed variable labels. Read one handwritten symbol
per cell; do not infer a symbol from a neighboring cell. There is a separate
variables strip beneath the grid. Return JSON only with this exact shape:
{"grid":[17 arrays of 12 strings or null]}
Rows 0-15 are the program grid and row 16 is the variables strip. Put the
values for a, b, and c in columns 0, 1, and 2 of row 16; all other row-16
cells must be null. Use null for empty cells. Preserve the symbols exactly.
Allowed symbols are
>, <, ^, v, R, I, {, }, P, =, digits 0-9, and variables a, b, c.
Do not include the printed grid lines, registration marks, title, or legend.
'''),
        DataPart('image/jpeg', imageBytes),
      ]),
    ]);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw StateError('Gemini returned an empty symbol recognition response.');
    }
    return _parse(text);
  }

  List<List<String?>> _parse(String text) {
    final normalized = text
        .trim()
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
    final decoded = jsonDecode(normalized) as Map<String, dynamic>;
    final rows = decoded['grid'];
    if (rows is! List || rows.length != 17) {
      throw const FormatException('Gemini returned an invalid grid row count.');
    }
    final grid = <List<String?>>[];
    for (final row in rows) {
      if (row is! List || row.length != 12) {
        throw const FormatException(
            'Gemini returned an invalid grid column count.');
      }
      grid.add(row.map((cell) {
        if (cell == null) return null;
        if (cell is! String || cell.length != 1) {
          throw const FormatException('Gemini returned an invalid cell.');
        }
        if (!RegExp(r'^[><^vRI{}P=0-9abcABC]$').hasMatch(cell)) {
          throw FormatException('Gemini returned invalid symbol "$cell".');
        }
        return cell;
      }).toList());
    }
    return grid;
  }
}
