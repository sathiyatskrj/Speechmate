import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/tts_service.dart';

/// Live AR Translator
/// Primary: ML Kit Object Detection (stream mode) — detects objects with bounding boxes live
/// Fallback: Text Recognition — reads printed text from the scene
class ARTranslatorScreen extends StatefulWidget {
  const ARTranslatorScreen({super.key});

  @override
  State<ARTranslatorScreen> createState() => _ARTranslatorScreenState();
}

class _ARTranslatorScreenState extends State<ARTranslatorScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {

  // Camera
  CameraController? _cameraController;
  CameraDescription? _camera;
  bool _isCameraReady = false;

  // ML Engines
  late ObjectDetector _objectDetector;
  late TextRecognizer _textRecognizer;
  final TtsService _ttsService = TtsService();

  // Processing state
  bool _isDetecting = false;
  DateTime _lastFrame = DateTime.now();
  static const int _throttleMs = 700;

  // Results
  List<_DetectedItem> _items = [];
  String _lastSpoken = '';
  Timer? _speakTimer;

  // UI mode: 'live' or 'paused'
  bool _isPaused = false;

  // Animations
  late AnimationController _scanAnim;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scanAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);

    _initDetector();
    _initTextRecognizer();
    _ttsService.init();
    _initCamera();
  }

  void _initDetector() {
    // STREAM mode = optimized for continuous video frames (lower latency)
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  void _initTextRecognizer() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.medium, // medium = best balance for ML processing
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraReady = true);
      _cameraController!.startImageStream(_onFrame);
    } catch (e) {
      debugPrint('[AR] Camera error: $e');
    }
  }

  // ─────────────────── Frame Processing ─────────────────────────────────────

  Future<void> _onFrame(CameraImage image) async {
    if (_isPaused) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame).inMilliseconds < _throttleMs) return;
    if (_isDetecting) return;

    _lastFrame = now;
    _isDetecting = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final items = <_DetectedItem>[];

      // ── Engine 1: Object Detection ──────────────────────────────────────
      try {
        final detected = await _objectDetector.processImage(inputImage);
        for (final obj in detected) {
          if (obj.labels.isEmpty) continue;
          final label = obj.labels.reduce(
              (a, b) => a.confidence > b.confidence ? a : b);
          if (label.confidence < 0.45) continue;

          // Clean up label text: "Home good" → "home", "Fashion good" → skip
          final rawText = label.text.toLowerCase();
          if (_isUselessLabel(rawText)) continue;

          final nic = await _lookupNicobarese(rawText);
          items.add(_DetectedItem(
            english: _cap(rawText),
            nicobarese: nic ?? _cap(rawText),
            confidence: label.confidence,
            hasTranslation: nic != null,
            boundingBox: obj.boundingBox,
          ));
        }
      } catch (e) {
        debugPrint('[AR] ObjectDetector error: $e');
      }

      // ── Engine 2: Text Recognition (if object detection found nothing) ──
      if (items.isEmpty) {
        try {
          final recognized = await _textRecognizer.processImage(inputImage);
          for (final block in recognized.blocks) {
            final words = block.text.split(RegExp(r'\s+'));
            for (final word in words) {
              if (word.length < 3) continue;
              final nic = await _lookupNicobarese(word);
              if (nic != null) {
                items.add(_DetectedItem(
                  english: _cap(word),
                  nicobarese: nic,
                  confidence: 0.9,
                  hasTranslation: true,
                  boundingBox: block.boundingBox,
                ));
                break;
              }
            }
            if (items.length >= 3) break;
          }
        } catch (e) {
          debugPrint('[AR] TextRecognizer error: $e');
        }
      }

      if (!mounted) return;
      setState(() => _items = items);

      // Auto-speak top item
      if (items.isNotEmpty && items.first.hasTranslation) {
        final top = items.first;
        if (top.nicobarese != _lastSpoken) {
          _lastSpoken = top.nicobarese;
          _speakTimer?.cancel();
          _speakTimer = Timer(const Duration(milliseconds: 1500), () {
            if (!_isPaused && mounted) {
              _ttsService.speakNicobarese(top.nicobarese,
                  englishWord: top.english);
            }
          });
        }
      }
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (_camera == null) return null;

    final rotation =
        InputImageRotationValue.fromRawValue(_camera!.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (Platform.isAndroid) {
      // NV21: concatenate all planes into a single byte array
      final allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return InputImage.fromBytes(
        bytes: allBytes.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    // iOS: single BGRA plane
    if (image.planes.length != 1) return null;
    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  // ─────────────────── Helpers ───────────────────────────────────────────────

  bool _isUselessLabel(String label) {
    const skip = {
      'product', 'room', 'indoor', 'outdoor', 'home good',
      'fashion good', 'place', 'unknown', 'other',
    };
    return skip.any((s) => label.contains(s));
  }

  Future<String?> _lookupNicobarese(String word) async {
    try {
      final db = await DatabaseManager.instance.database;
      final term = word.toLowerCase().trim();

      var rows = await db.query('words',
          where: 'LOWER(english) = ?', whereArgs: [term], limit: 1);
      if (rows.isNotEmpty) {
        final v = rows.first['nicobarese']?.toString() ?? '';
        if (v.isNotEmpty) return v;
      }

      rows = await db.query('words',
          where: 'LOWER(english) LIKE ?', whereArgs: ['%$term%'], limit: 1);
      if (rows.isNotEmpty) {
        final v = rows.first['nicobarese']?.toString() ?? '';
        if (v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _scanAnim.stop();
      } else {
        _items = [];
        _lastSpoken = '';
        _scanAnim.repeat(reverse: true);
      }
    });
  }

  // ─────────────────── Lifecycle ─────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !(_cameraController!.value.isInitialized)) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.stopImageStream();
    } else if (state == AppLifecycleState.resumed && !_isPaused) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnim.dispose();
    _pulseAnim.dispose();
    _speakTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _objectDetector.close();
    _textRecognizer.close();
    _ttsService.dispose();
    super.dispose();
  }

  // ─────────────────── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        // 1. Camera feed
        if (_isCameraReady && _cameraController != null)
          _CameraView(controller: _cameraController!)
        else
          _buildBootScreen(),

        // 2. Bounding box overlay
        if (_isCameraReady && _items.isNotEmpty && _cameraController != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _BoxOverlayPainter(
                items: _items,
                previewSize: _cameraController!.value.previewSize!,
                screenSize: MediaQuery.of(context).size,
              ),
            ),
          ),

        // 3. HUD scan frame
        if (_isCameraReady && !_isPaused)
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, __) => CustomPaint(
              painter: _ScanFramePainter(progress: _scanAnim.value),
              size: Size.infinite,
            ),
          ),

        // 4. Top bar
        Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

        // 5. Translation cards
        if (_items.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: _buildCards(),
          ),

        // 6. Status hint when empty
        if (_isCameraReady && _items.isEmpty && !_isPaused)
          Positioned(
            bottom: 140,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '🔍  Point camera at objects or text',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),

        // 7. Bottom bar
        Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
      ]),
    );
  }

  Widget _buildBootScreen() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 16),
          const Text('INITIALIZING OPTICS…',
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
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          style: IconButton.styleFrom(backgroundColor: Colors.black45),
        ),
        const Spacer(),
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.5)),
            ),
            child: const Text('A.R. LIVE TRANSLATOR',
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPaused
                      ? Colors.white38
                      : Color.lerp(Colors.green, Colors.cyanAccent,
                          _pulseAnim.value)!,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _isPaused ? 'PAUSED' : 'LIVE',
              style: TextStyle(
                  color: _isPaused ? Colors.white38 : Colors.cyanAccent,
                  fontSize: 9,
                  letterSpacing: 2),
            ),
          ]),
        ]),
        const Spacer(),
        IconButton(
          onPressed: _togglePause,
          icon: Icon(
            _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: _isPaused ? Colors.cyanAccent : Colors.white,
          ),
          style: IconButton.styleFrom(
            backgroundColor:
                _isPaused ? Colors.black45 : Colors.redAccent.withValues(alpha: 0.7),
          ),
        ),
      ]),
    );
  }

  Widget _buildCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _items.take(3).toList().asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return GestureDetector(
          onTap: () => _ttsService.speakNicobarese(item.nicobarese,
              englishWord: item.english),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: i == 0
                  ? Colors.black.withValues(alpha: 0.8)
                  : Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.hasTranslation
                    ? (i == 0 ? Colors.cyanAccent : Colors.cyanAccent.withValues(alpha: 0.4))
                    : Colors.white24,
                width: i == 0 ? 1.5 : 1,
              ),
              boxShadow: i == 0 && item.hasTranslation
                  ? [BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      blurRadius: 12)]
                  : [],
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.english,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11, letterSpacing: 1),
                    ),
                    Text(
                      item.nicobarese,
                      style: TextStyle(
                        color: item.hasTranslation ? Colors.white : Colors.white38,
                        fontSize: i == 0 ? 26 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.hasTranslation)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_up_rounded,
                      color: Colors.cyanAccent, size: 18),
                ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 16,
          left: 24,
          right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.transparent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomBtn(
            icon: Icons.clear_all_rounded,
            label: 'Clear',
            onTap: () => setState(() {
              _items = [];
              _lastSpoken = '';
            }),
          ),
          // Live indicator dot
          Column(children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                final r = 10.0 + (_isPaused ? 0 : _pulseAnim.value * 4);
                return Container(
                  width: r * 2, height: r * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPaused
                        ? Colors.white12
                        : Colors.cyanAccent.withValues(alpha: 0.15),
                    border: Border.all(
                      color: _isPaused ? Colors.white24 : Colors.cyanAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _isPaused ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    color: _isPaused ? Colors.white38 : Colors.cyanAccent,
                    size: 16,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(_isPaused ? 'OFF' : 'ON',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 1)),
          ]),
          _BottomBtn(
            icon: Icons.volume_up_rounded,
            label: 'Replay',
            onTap: _items.isEmpty
                ? null
                : () => _ttsService.speakNicobarese(
                    _items.first.nicobarese,
                    englishWord: _items.first.english),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── WIDGETS ─────────────────────────────────────────

class _CameraView extends StatelessWidget {
  final CameraController controller;
  const _CameraView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize!.height,
          height: controller.value.previewSize!.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _BottomBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1.0,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ─────────────────────────── DATA ────────────────────────────────────────────

class _DetectedItem {
  final String english;
  final String nicobarese;
  final double confidence;
  final bool hasTranslation;
  final Rect? boundingBox;

  const _DetectedItem({
    required this.english,
    required this.nicobarese,
    required this.confidence,
    required this.hasTranslation,
    this.boundingBox,
  });
}

// ─────────────────────────── PAINTERS ────────────────────────────────────────

class _BoxOverlayPainter extends CustomPainter {
  final List<_DetectedItem> items;
  final Size previewSize;
  final Size screenSize;

  const _BoxOverlayPainter({
    required this.items,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factors: preview is landscape, screen is portrait
    final scaleX = screenSize.width / previewSize.height;
    final scaleY = screenSize.height / previewSize.width;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.boundingBox == null) continue;

      final box = item.boundingBox!;
      final scaled = Rect.fromLTRB(
        box.left * scaleX,
        box.top * scaleY,
        box.right * scaleX,
        box.bottom * scaleY,
      );

      final color = i == 0 ? Colors.cyanAccent : Colors.white54;

      // Draw bounding box
      final boxPaint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = i == 0 ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
          RRect.fromRectAndRadius(scaled, const Radius.circular(6)), boxPaint);

      // Draw label badge above box
      final tp = TextPainter(
        text: TextSpan(
          text: ' ${item.nicobarese} ',
          style: TextStyle(
              color: Colors.white,
              fontSize: i == 0 ? 14 : 11,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeRect = Rect.fromLTWH(
        scaled.left,
        (scaled.top - tp.height - 6).clamp(0, size.height),
        tp.width + 8,
        tp.height + 4,
      );

      final bgPaint = Paint()
        ..color = (i == 0 ? Colors.cyanAccent : Colors.black87)
            .withValues(alpha: 0.85);
      canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
          bgPaint);

      tp.paint(
        canvas,
        Offset(badgeRect.left + 4,
            badgeRect.top + (badgeRect.height - tp.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_BoxOverlayPainter old) => true;
}

class _ScanFramePainter extends CustomPainter {
  final double progress;
  _ScanFramePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final w = size.width * 0.8, h = size.height * 0.45;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);

    final bp = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const c = 26.0;
    void corner(Offset o, Offset dx, Offset dy) {
      canvas.drawLine(o, o + dx, bp);
      canvas.drawLine(o, o + dy, bp);
    }

    corner(rect.topLeft, const Offset(c, 0), const Offset(0, c));
    corner(rect.topRight, const Offset(-c, 0), const Offset(0, c));
    corner(rect.bottomLeft, const Offset(c, 0), const Offset(0, -c));
    corner(rect.bottomRight, const Offset(-c, 0), const Offset(0, -c));

    // Scan line
    final sy = rect.top + rect.height * progress;
    final sp = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawLine(Offset(rect.left, sy), Offset(rect.right, sy), sp);

    // Trail gradient
    final gradRect =
        Rect.fromLTRB(rect.left, sy - 40, rect.right, sy);
    canvas.drawRect(
      gradRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, gradRect.top),
          Offset(0, gradRect.bottom),
          [Colors.cyanAccent.withValues(alpha: 0.0), Colors.cyanAccent.withValues(alpha: 0.2)],
        ),
    );
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.progress != progress;
}
