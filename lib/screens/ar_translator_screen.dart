import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/tts_service.dart';

/// Next-Gen AR Translator HUD
/// Uses Google ML Kit Image Labeling + Text Recognition for robust object/text detection
class ARTranslatorScreen extends StatefulWidget {
  const ARTranslatorScreen({super.key});

  @override
  State<ARTranslatorScreen> createState() => _ARTranslatorScreenState();
}

class _ARTranslatorScreenState extends State<ARTranslatorScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  CameraDescription? _camera;
  ImageLabeler? _imageLabeler;
  late TextRecognizer _textRecognizer;
  final TtsService _ttsService = TtsService();

  bool _isDetecting = false;
  bool _isCameraReady = false;
  bool _isLive = true;
  bool _labelerReady = false;

  List<_ARLabel> _detectedLabels = [];
  String _lastSpoken = '';
  Timer? _ttsTimer;

  DateTime _lastProcessed = DateTime.now();
  static const _throttleMs = 800;

  late AnimationController _scannerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _ttsService.init();
    _initLabeler();
    _initCamera();
  }

  void _initLabeler() {
    try {
      // Use default options — model is auto-downloaded by ML Kit on first run
      // or bundled via build.gradle. Lower threshold to 0.5 for better detection.
      final options = ImageLabelerOptions(confidenceThreshold: 0.5);
      _imageLabeler = ImageLabeler(options: options);
      _labelerReady = true;
    } catch (e) {
      debugPrint('[ARTranslator] ImageLabeler init failed: $e — will use text-only mode');
      _labelerReady = false;
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('[ARTranslator] No cameras found');
        return;
      }

      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.medium, // medium is more stable than high for streaming
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('[ARTranslator] Camera init error: $e');
      if (mounted) {
        setState(() => _isCameraReady = false);
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < _throttleMs) return;
    if (_isDetecting || !_isLive) return;
    _lastProcessed = now;
    _isDetecting = true;

    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final arLabels = <_ARLabel>[];

      // 1. Try Image Labeling (object recognition)
      if (_labelerReady && _imageLabeler != null) {
        try {
          final labels = await _imageLabeler!.processImage(inputImage);
          for (final label in labels) {
            final text = label.label.toLowerCase();
            final confidence = label.confidence;
            if (text == 'product' || text == 'room' || text == 'indoor' || confidence < 0.5) continue;

            final translation = await _lookupNicobarese(text);
            arLabels.add(_ARLabel(
              englishLabel: _capitalize(text),
              nicobareseLabel: translation,
              confidence: confidence,
              source: 'Object',
            ));
          }
        } catch (e) {
          debugPrint('[ARTranslator] Labeling error: $e');
          // Don't crash — fall through to text recognition
        }
      }

      // 2. Also try Text Recognition (so it works even without model)
      if (arLabels.isEmpty) {
        try {
          final recognizedText = await _textRecognizer.processImage(inputImage);
          for (final block in recognizedText.blocks) {
            final text = block.text.trim();
            if (text.length < 2) continue;
            final firstWord = text.split(RegExp(r'\s+')).first.toLowerCase();
            if (firstWord.isEmpty) continue;

            final translation = await _lookupNicobarese(firstWord);
            if (translation != _capitalize(firstWord)) {
              // Only show if we found an actual translation
              arLabels.add(_ARLabel(
                englishLabel: _capitalize(firstWord),
                nicobareseLabel: translation,
                confidence: 0.85,
                source: 'Text',
              ));
              break; // One block at a time
            }
          }
        } catch (e) {
          debugPrint('[ARTranslator] Text recognition error: $e');
        }
      }

      arLabels.sort((a, b) => b.confidence.compareTo(a.confidence));
      final topLabels = arLabels.take(4).toList();

      if (mounted) {
        setState(() => _detectedLabels = topLabels);

        if (topLabels.isNotEmpty) {
          final top = topLabels.first;
          if (top.nicobareseLabel != _lastSpoken &&
              top.nicobareseLabel != top.englishLabel) {
            _lastSpoken = top.nicobareseLabel;
            _ttsTimer?.cancel();
            _ttsTimer = Timer(const Duration(milliseconds: 1200), () {
              if (_isLive && mounted) {
                _ttsService.speakNicobarese(
                  top.nicobareseLabel,
                  englishWord: top.englishLabel,
                );
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[ARTranslator] Frame processing error: $e');
    }
    _isDetecting = false;
  }

  InputImage? _toInputImage(CameraImage image) {
    if (_camera == null) return null;

    final rotation =
        InputImageRotationValue.fromRawValue(_camera!.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (Platform.isAndroid) {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

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

  Future<String> _lookupNicobarese(String englishLabel) async {
    try {
      final db = await DatabaseManager.instance.database;
      final term = englishLabel.toLowerCase().trim();

      // Exact match
      final exact = await db.query('words',
          where: 'LOWER(english) = ?', whereArgs: [term], limit: 1);
      if (exact.isNotEmpty &&
          (exact.first['nicobarese'] ?? '').toString().isNotEmpty) {
        return exact.first['nicobarese'].toString();
      }

      // Contains match
      final fuzzy = await db.query('words',
          where: 'LOWER(english) LIKE ?', whereArgs: ['%$term%'], limit: 1);
      if (fuzzy.isNotEmpty &&
          (fuzzy.first['nicobarese'] ?? '').toString().isNotEmpty) {
        return fuzzy.first['nicobarese'].toString();
      }

      // Word splitting (e.g. "person walking" -> try "person" then "walking")
      if (term.contains(' ')) {
        for (final word in term.split(' ')) {
          if (word.length < 3) continue;
          final split = await db.query('words',
              where: 'LOWER(english) LIKE ?',
              whereArgs: ['%$word%'],
              limit: 1);
          if (split.isNotEmpty &&
              (split.first['nicobarese'] ?? '').toString().isNotEmpty) {
            return split.first['nicobarese'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('[ARTranslator] Lookup error: $e');
    }
    return _capitalize(englishLabel);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _toggleLive() {
    setState(() {
      _isLive = !_isLive;
      if (!_isLive) {
        _detectedLabels = [];
        _scannerController.stop();
      } else {
        _scannerController.repeat(reverse: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      if (_isLive) _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _pulseController.dispose();
    _ttsTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _imageLabeler?.close();
    _textRecognizer.close();
    _ttsService.dispose();
    super.dispose();
  }

  // ─────────────────────────────────── UI ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (_isCameraReady && _cameraController != null)
            _buildCameraPreview()
          else
            _buildLoadingView(),

          // AR Overlay Effects
          if (_isCameraReady && _isLive) ...[
            _buildScanGrid(),
            _buildHUDScanner(),
          ],

          // Labels Float
          if (_isCameraReady && _detectedLabels.isNotEmpty)
            _buildFloatingLabels(),

          // No detection hint
          if (_isCameraReady && _isLive && _detectedLabels.isEmpty)
            Positioned(
              bottom: 160,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔍 Point at objects or text',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            ),

          // Top Navigation
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

          // Bottom Control Panel
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Transform.scale(
      scale: 1.02,
      child: Center(child: CameraPreview(_cameraController!)),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 16),
          const Text('INITIALIZING OPTICS...',
              style: TextStyle(
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                  letterSpacing: 2)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _initCamera,
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            label: const Text('Retry', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanGrid() {
    return CustomPaint(
      painter: _GridPainter(pulseAnimation: _pulseController),
      size: Size.infinite,
    );
  }

  Widget _buildHUDScanner() {
    return AnimatedBuilder(
      animation: _scannerController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScannerPainter(scanProgress: _scannerController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFloatingLabels() {
    final top = _detectedLabels.first;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.8), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.center_focus_weak, color: Colors.cyanAccent, size: 22),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    top.source.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.cyanAccent, fontSize: 10, letterSpacing: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              top.nicobareseLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                top.englishLabel.toUpperCase(),
                style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar, color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(
                  'MATCH: ${(top.confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _ttsService.speakNicobarese(
                      top.nicobareseLabel,
                      englishWord: top.englishLabel),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up, color: Colors.cyanAccent, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'A.R. TRANSLATOR',
                  style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                ),
              ),
              if (!_labelerReady)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Text-Only Mode', style: TextStyle(color: Colors.amberAccent, fontSize: 10)),
                ),
            ],
          ),
          IconButton(
            onPressed: _toggleLive,
            icon: Icon(_isLive ? Icons.pause : Icons.play_arrow,
                color: _isLive ? Colors.white : Colors.cyanAccent),
            style: IconButton.styleFrom(
                backgroundColor: _isLive
                    ? Colors.redAccent.withValues(alpha: 0.8)
                    : Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_detectedLabels.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          top: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text('ENVIRONMENT ANALYSIS',
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _detectedLabels.length - 1,
              itemBuilder: (context, index) {
                final label = _detectedLabels[index + 1];
                return GestureDetector(
                  onTap: () => _ttsService.speakNicobarese(
                      label.nicobareseLabel,
                      englishWord: label.englishLabel),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label.nicobareseLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text(label.englishLabel,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────── DATA ───────────────────────────────────

class _ARLabel {
  final String englishLabel;
  final String nicobareseLabel;
  final double confidence;
  final String source;

  const _ARLabel({
    required this.englishLabel,
    required this.nicobareseLabel,
    required this.confidence,
    this.source = 'Object',
  });
}

// ─────────────────────────────────── PAINTERS ───────────────────────────────

class _GridPainter extends CustomPainter {
  final Animation<double> pulseAnimation;

  _GridPainter({required this.pulseAnimation}) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
          .withValues(alpha: 0.04 + (pulseAnimation.value * 0.04))
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => true;
}

class _ScannerPainter extends CustomPainter {
  final double scanProgress;

  _ScannerPainter({required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final boxSize = size.width * 0.72;
    final rect = Rect.fromCenter(center: center, width: boxSize, height: boxSize);

    final bracketPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const cornerLength = 32.0;

    // Corner brackets
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, cornerLength), bracketPaint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(-cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, cornerLength), bracketPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -cornerLength), bracketPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(0, -cornerLength), bracketPaint);

    // Scan Line
    final scanLineY = rect.top + (rect.height * scanProgress);
    final scanLinePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    canvas.drawLine(
        Offset(rect.left, scanLineY), Offset(rect.right, scanLineY), scanLinePaint);

    // Gradient trail
    final gradientRect =
        Rect.fromLTRB(rect.left, scanLineY - 50, rect.right, scanLineY);
    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, gradientRect.top),
        Offset(0, gradientRect.bottom),
        [
          Colors.cyanAccent.withValues(alpha: 0.0),
          Colors.cyanAccent.withValues(alpha: 0.25)
        ],
      );
    canvas.drawRect(gradientRect, gradientPaint);
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress;
}
