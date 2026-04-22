import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/tts_service.dart';

/// AR Translator — uses Text Recognition (guaranteed offline) as primary engine.
/// Tap the scan button to detect objects/text and get Nicobarese translations.
class ARTranslatorScreen extends StatefulWidget {
  const ARTranslatorScreen({super.key});

  @override
  State<ARTranslatorScreen> createState() => _ARTranslatorScreenState();
}

class _ARTranslatorScreenState extends State<ARTranslatorScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  CameraDescription? _camera;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final TtsService _ttsService = TtsService();

  bool _isCameraReady = false;
  bool _isScanning = false;

  List<_ARResult> _results = [];
  String _statusMsg = 'Point camera at text or objects, then tap scan';

  late AnimationController _scanAnim;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _ttsService.init();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _statusMsg = 'No camera found on this device.');
        return;
      }
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('[AR] Camera error: $e');
      if (mounted) setState(() => _statusMsg = 'Camera error: $e');
    }
  }

  /// Take a photo and run text recognition on it
  Future<void> _scanNow() async {
    if (!_isCameraReady || _isScanning) return;
    setState(() {
      _isScanning = true;
      _results = [];
      _statusMsg = 'Scanning…';
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognized =
          await _textRecognizer.processImage(inputImage);

      final newResults = <_ARResult>[];

      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final raw = line.text.trim();
          if (raw.length < 2) continue;
          // look up each word in the line
          for (final word in raw.split(RegExp(r'\s+'))) {
            if (word.length < 2) continue;
            final nic = await _lookupNicobarese(word);
            if (nic != null) {
              newResults.add(_ARResult(english: _cap(word), nicobarese: nic));
              break; // one translation per line is enough
            }
          }
          if (newResults.length >= 6) break;
        }
        if (newResults.length >= 6) break;
      }

      if (newResults.isEmpty) {
        setState(() => _statusMsg =
            'No Nicobarese words found. Try pointing at printed text.');
      } else {
        setState(() {
          _results = newResults;
          _statusMsg = '${newResults.length} word(s) found!';
        });
        _ttsService.speakNicobarese(
          newResults.first.nicobarese,
          englishWord: newResults.first.english,
        );
      }
    } catch (e) {
      debugPrint('[AR] Scan error: $e');
      setState(() => _statusMsg = 'Scan failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<String?> _lookupNicobarese(String word) async {
    try {
      final db = await DatabaseManager.instance.database;
      final term = word.toLowerCase().trim();
      final exact = await db.query('words',
          where: 'LOWER(english) = ?', whereArgs: [term], limit: 1);
      if (exact.isNotEmpty) {
        final v = exact.first['nicobarese']?.toString() ?? '';
        if (v.isNotEmpty) return v;
      }
      final fuzzy = await db.query('words',
          where: 'LOWER(english) LIKE ?', whereArgs: ['%$term%'], limit: 1);
      if (fuzzy.isNotEmpty) {
        final v = fuzzy.first['nicobarese']?.toString() ?? '';
        if (v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  void dispose() {
    _scanAnim.dispose();
    _pulseAnim.dispose();
    _cameraController?.dispose();
    _textRecognizer.close();
    _ttsService.dispose();
    super.dispose();
  }

  // ─────────────────────────── UI ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        // Camera
        if (_isCameraReady && _cameraController != null)
          CameraPreview(_cameraController!)
        else
          _buildLoading(),

        // Scan frame overlay
        if (_isCameraReady) _buildScanFrame(),

        // Results overlay
        if (_results.isNotEmpty) _buildResultsOverlay(),

        // Top bar
        Positioned(
            top: 0, left: 0, right: 0, child: _buildTopBar()),

        // Bottom controls
        Positioned(
            bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
      ]),
    );
  }

  Widget _buildLoading() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 16),
          const Text('INITIALIZING CAMERA…',
              style: TextStyle(
                  color: Colors.cyanAccent,
                  letterSpacing: 2,
                  fontFamily: 'monospace')),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _initCamera,
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            label: const Text('Retry',
                style: TextStyle(color: Colors.cyanAccent)),
          ),
        ]),
      );

  Widget _buildScanFrame() {
    return AnimatedBuilder(
      animation: _scanAnim,
      builder: (_, __) => CustomPaint(
        painter: _FramePainter(progress: _scanAnim.value, active: _isScanning),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.cyanAccent),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.6)),
            ),
            child: const Text('A.R. TRANSLATOR',
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ),
          const Spacer(),
          // Clear button
          IconButton(
            onPressed: _results.isEmpty
                ? null
                : () => setState(() {
                      _results = [];
                      _statusMsg =
                          'Point camera at text or objects, then tap scan';
                    }),
            icon: Icon(Icons.close,
                color: _results.isEmpty
                    ? Colors.transparent
                    : Colors.white70),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          top: 24,
          left: 24,
          right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.black87, Colors.transparent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Status message
        Text(
          _statusMsg,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: _results.isEmpty ? Colors.white54 : Colors.cyanAccent,
              fontSize: 13),
        ),
        const SizedBox(height: 20),
        // Big Scan Button
        GestureDetector(
          onTap: _isScanning ? null : _scanNow,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) {
              final scale = _isScanning
                  ? 1.0 + _pulseAnim.value * 0.08
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isScanning
                          ? Colors.cyanAccent
                          : Colors.white,
                      width: 4,
                    ),
                    color: _isScanning
                        ? Colors.cyanAccent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.15),
                    boxShadow: _isScanning
                        ? [
                            BoxShadow(
                              color: Colors.cyanAccent
                                  .withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 4,
                            )
                          ]
                        : [],
                  ),
                  child: _isScanning
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.cyanAccent, strokeWidth: 2))
                      : const Icon(Icons.document_scanner_rounded,
                          color: Colors.white, size: 36),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text('TAP TO SCAN',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 2)),
      ]),
    );
  }

  Widget _buildResultsOverlay() {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _results.asMap().entries.map((e) {
              final idx = e.key;
              final r = e.value;
              return GestureDetector(
                onTap: () => _ttsService.speakNicobarese(r.nicobarese,
                    englishWord: r.english),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: idx == 0
                          ? Colors.cyanAccent
                          : Colors.white24,
                      width: idx == 0 ? 2 : 1,
                    ),
                    boxShadow: idx == 0
                        ? [
                            BoxShadow(
                              color:
                                  Colors.cyanAccent.withValues(alpha: 0.3),
                              blurRadius: 16,
                            )
                          ]
                        : [],
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.english,
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(r.nicobarese,
                                style: TextStyle(
                                    color: idx == 0
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: idx == 0 ? 28 : 22,
                                    fontWeight: FontWeight.bold)),
                          ]),
                    ),
                    Icon(Icons.volume_up_rounded,
                        color: idx == 0
                            ? Colors.cyanAccent
                            : Colors.white38,
                        size: 24),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── DATA ─────────────────────────────────────

class _ARResult {
  final String english;
  final String nicobarese;
  const _ARResult({required this.english, required this.nicobarese});
}

// ─────────────────────────────── PAINTER ──────────────────────────────────

class _FramePainter extends CustomPainter {
  final double progress;
  final bool active;
  _FramePainter({required this.progress, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.75;
    final h = size.height * 0.38;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);

    final bracketPaint = Paint()
      ..color = active ? Colors.cyanAccent : Colors.white54
      ..strokeWidth = active ? 3.5 : 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const c = 28.0;
    void corner(Offset a, Offset b, Offset cc) {
      canvas.drawLine(a, b, bracketPaint);
      canvas.drawLine(a, cc, bracketPaint);
    }

    corner(rect.topLeft, rect.topLeft.translate(c, 0),
        rect.topLeft.translate(0, c));
    corner(rect.topRight, rect.topRight.translate(-c, 0),
        rect.topRight.translate(0, c));
    corner(rect.bottomLeft, rect.bottomLeft.translate(c, 0),
        rect.bottomLeft.translate(0, -c));
    corner(rect.bottomRight, rect.bottomRight.translate(-c, 0),
        rect.bottomRight.translate(0, -c));

    if (active) {
      final scanY = rect.top + rect.height * progress;
      final linePaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
      canvas.drawLine(
          Offset(rect.left, scanY), Offset(rect.right, scanY), linePaint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.progress != progress || old.active != active;
}
