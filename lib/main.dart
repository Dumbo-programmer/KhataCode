import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'languages/symbol_runner.dart';
import 'languages/html_runner.dart';
import 'crop.dart';
import 'html_cleanup.dart';
import 'models.dart';
import 'tokenizer.dart';

void main() => runApp(const KhataCodeApp());

enum ScanMode { html, symbols }

class KhataCodeApp extends StatelessWidget {
  const KhataCodeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'KhataCode',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomeScreen());
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('KhataCode',
                    style:
                        TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Photograph handwritten HTML or a symbolic program.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20)),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => _openCapture(context, ScanMode.html),
                    child:
                        const Text('Scan HTML', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => _openCapture(context, ScanMode.symbols),
                    child: const Text('Scan symbol sheet',
                        style: TextStyle(fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCapture(BuildContext context, ScanMode mode) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => CaptureScreen(mode: mode)));
  }
}

class CaptureScreen extends StatefulWidget {
  final ScanMode mode;
  const CaptureScreen({super.key, required this.mode});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  bool busy = false;
  bool starting = false;
  String? busyPhoto;
  String? permissionMessage;
  TextRecognizer? recognizer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    if (starting || !mounted) return;
    starting = true;
    try {
      if (!await Permission.camera.request().isGranted) {
        if (mounted) {
          setState(() =>
              permissionMessage = 'Camera access is needed to scan a sheet.');
        }
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No camera is available.');
      recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
      final nextController = CameraController(
          cameras.first, ResolutionPreset.high,
          enableAudio: false);
      await nextController.initialize();
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      controller = nextController;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => permissionMessage = 'Could not start the camera: $e');
      }
    } finally {
      starting = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final activeController = controller;
      controller = null;
      activeController?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && controller == null) {
      _start();
    }
  }

  Future<void> _scan() async {
    if (busy || controller == null || !controller!.value.isInitialized) return;
    setState(() => busy = true);
    String? error;
    try {
      final photo = await controller!.takePicture();
      if (mounted) setState(() => busyPhoto = photo.path);
      final result = await _process(photo);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ResultScreen(result: result, thumbnail: photo.path)));
    } catch (e) {
      error = '$e';
    }
    if (mounted && error != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ResultScreen(
                  result: PipelineResult(error: error!, mode: widget.mode),
                  thumbnail: null)));
    }
    if (mounted) {
      setState(() {
        busy = false;
        busyPhoto = null;
      });
    }
  }

  Future<PipelineResult> _process(XFile photo) async {
    if (widget.mode == ScanMode.html) {
      return _processHtml(photo);
    }
    final prepared = await compute(prepareCapture, await photo.readAsBytes());
    if (prepared.blank) {
      throw const ProgramError(
          'Nothing detected, try again with the sheet flat and well lit.');
    }
    final recognized =
        await recognizer!.processImage(InputImage.fromFilePath(photo.path));
    final grid = List.generate(17, (_) => List<String?>.filled(12, null));
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final text = element.text;
          final box = element.boundingBox;
          for (var i = 0; i < text.length; i++) {
            final col = ((box.left + box.width * (i + .5) / text.length) / 100)
                .floor()
                .clamp(0, 11)
                .toInt();
            final row = (box.top / 100).floor().clamp(0, 16).toInt();
            grid[row][col] = text[i];
          }
        }
      }
    }
    final program = tokenize(grid);
    final html = SymbolRunner(program.vars).build(program.cells);
    return PipelineResult(html: html, mode: ScanMode.symbols, tokens: grid);
  }

  Future<PipelineResult> _processHtml(XFile photo) async {
    final prepared =
        await compute(prepareHtmlCapture, await photo.readAsBytes());
    if (prepared.blank) {
      throw const ProgramError(
          'Nothing detected, try again with the sheet flat and well lit.');
    }
    final processedPath = '${photo.path}.html.png';
    await File(processedPath).writeAsBytes(prepared.bytes);
    try {
      final recognized = await recognizer!
          .processImage(InputImage.fromFilePath(processedPath));
      final lines = recognized.blocks.expand((block) => block.lines).toList();
      lines.sort((a, b) {
        final verticalDifference =
            a.boundingBox.center.dy - b.boundingBox.center.dy;
        final lineHeight = (a.boundingBox.height + b.boundingBox.height) / 2;
        if (verticalDifference.abs() <= lineHeight / 2) {
          return a.boundingBox.left.compareTo(b.boundingBox.left);
        }
        return verticalDifference < 0 ? -1 : 1;
      });
      final rawLines = lines.map((line) => line.text).toList();
      final cleanedLines = rawLines.map(cleanHtmlLine).toList();
      final cells = [
        for (var row = 0; row < cleanedLines.length; row++)
          Cell(row: row, col: 0, type: TokenType.text, raw: cleanedLines[row])
      ];
      final bodyText = cleanedLines.join('\n').trim();
      final html = HtmlRunner().build(cells);
      return PipelineResult(
          html: html,
          mode: ScanMode.html,
          bodyText: bodyText,
          rawLines: rawLines,
          cleanedLines: cleanedLines);
    } finally {
      await File(processedPath).delete();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    recognizer?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (permissionMessage != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Camera')),
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(permissionMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: openAppSettings,
                            child: const Text('Grant camera access')),
                      ]))));
    }
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(widget.mode == ScanMode.html
                ? 'Place the paper'
                : 'Place the sheet')),
        body: Stack(fit: StackFit.expand, children: [
          CameraPreview(controller!),
          Center(
              child: AspectRatio(
                  aspectRatio: 210 / 297,
                  child: Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.yellow, width: 4))))),
          if (busy)
            Container(
                color: Colors.black54,
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (busyPhoto != null)
                    SizedBox(
                        width: 120,
                        height: 160,
                        child: Image.file(File(busyPhoto!), fit: BoxFit.cover)),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('Reading sheet…',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ]))),
          Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                  child: FloatingActionButton(
                      onPressed: busy ? null : _scan,
                      child: const Icon(Icons.camera_alt)))),
        ]));
  }
}

class PipelineResult {
  String? html;
  final String? error;
  final String? thumbnail;
  final ScanMode mode;
  final String? bodyText;
  final List<String> rawLines;
  final List<String> cleanedLines;
  final List<List<String?>> tokens;
  PipelineResult(
      {this.html,
      this.error,
      this.thumbnail,
      this.mode = ScanMode.symbols,
      this.bodyText,
      this.rawLines = const [],
      this.cleanedLines = const [],
      this.tokens = const []});
}

class ResultScreen extends StatefulWidget {
  final PipelineResult result;
  final String? thumbnail;
  const ResultScreen({super.key, required this.result, this.thumbnail});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String? webviewError;
  late final TextEditingController htmlController;

  @override
  void initState() {
    super.initState();
    htmlController = TextEditingController(text: widget.result.bodyText);
  }

  void _runEditedHtml() {
    try {
      final lines = htmlController.text.split('\n');
      final cells = [
        for (var row = 0; row < lines.length; row++)
          Cell(row: row, col: 0, type: TokenType.text, raw: lines[row])
      ];
      final html = HtmlRunner().build(cells);
      setState(() {
        widget.result.html = html;
        webviewError = null;
      });
    } on ProgramError catch (error) {
      setState(() => webviewError = error.message);
    }
  }

  @override
  void dispose() {
    htmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.result.error ?? webviewError;
    final output = error != null
        ? SingleChildScrollView(
            child: Text(
              webviewError == null
                  ? error
                  : '$error\n\nRaw HTML:\n${widget.result.html}',
              style: const TextStyle(fontSize: 20),
            ),
          )
        : InAppWebView(
            key: ValueKey(widget.result.html),
            initialData: InAppWebViewInitialData(
                data: widget.result.html ?? '<html><body></body></html>'),
            initialSettings: InAppWebViewSettings(javaScriptEnabled: false),
            onReceivedError: (controller, request, loadError) {
              setState(() => webviewError = loadError.description);
            },
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(flex: 3, child: output),
            if (widget.result.mode == ScanMode.html) ...[
              const SizedBox(height: 8),
              const Text(
                  'OCR can confuse <, >, /, =, and quotes. Edit the HTML below if needed.',
                  style: TextStyle(color: Colors.deepOrange)),
              const SizedBox(height: 8),
              TextField(
                controller: htmlController,
                minLines: 3,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                    labelText: 'Recognized HTML', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                    onPressed: _runEditedHtml, child: const Text('Run again')),
              ),
            ],
            ExpansionTile(
              title: const Text('Debug'),
              children: [
                if (widget.result.mode == ScanMode.html)
                  for (var row = 0; row < widget.result.rawLines.length; row++)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          '${row + 1}: ${widget.result.rawLines[row]}  ->  ${widget.result.cleanedLines[row]}'),
                    )
                else
                  for (var row = 0; row < widget.result.tokens.length; row++)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          '${row + 1}: ${widget.result.tokens[row].map((e) => e ?? '_').join()}'),
                    ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Scan again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
