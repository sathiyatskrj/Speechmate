import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/tts_service.dart';

/// Next-Gen AR Translator HUD
/// Uses Google ML Kit Image Labeling for robust object recognition
class ARTranslatorScreen extends StatefulWidget {
  const ARTranslatorScreen({super.key});

  @override
  State<ARTranslatorScreen> createState() => _ARTranslatorScreenState();
}

class _ARTranslatorScreenState extends State<ARTranslatorScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  CameraDescription? _camera;
  late ImageLabeler _imageLabeler;
  final TtsService _ttsService = TtsService();

  bool _isDetecting = false;
  bool _isCameraReady = false;
  bool _isLive = true;

  List<_ARLabel> _detectedLabels = [];
  String _lastSpoken = '';
  Timer? _ttsTimer;

  DateTime _lastProcessed = DateTime.now();
  static const _throttleMs = 600; // slightly longer to save battery, labeling is heavy

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

    _ttsService.init();
    _initLabeler();
    _initCamera();
  }

  void _initLabeler() {
    final options = ImageLabelerOptions(confidenceThreshold: 0.6); // Only high confidence
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      // Prefer back camera
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.high,
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
      if (inputImage == null) { _isDetecting = false; return; }

      final labels = await _imageLabeler.processImage(inputImage);
      final arLabels = <_ARLabel>[];

      for (final label in labels) {
        final text = label.label.toLowerCase();
        final confidence = label.confidence;
        
        // Filter out very generic labels that don't translate well
        if (text == 'product' || text == 'room') continue;

        final translation = await _lookupNicobarese(text);

        arLabels.add(_ARLabel(
          englishLabel: _capitalize(text),
          nicobareseLabel: translation,
          confidence: confidence,
        ));
      }

      // Sort by confidence
      arLabels.sort((a, b) => b.confidence.compareTo(a.confidence));
      // Keep top 4
      final topLabels = arLabels.take(4).toList();

      if (mounted) {
        setState(() => _detectedLabels = topLabels);
        
        // Auto-speak top label
        if (topLabels.isNotEmpty) {
          final top = topLabels.first;
          if (top.nicobareseLabel != _lastSpoken && top.nicobareseLabel != top.englishLabel) {
            _lastSpoken = top.nicobareseLabel;
            _ttsTimer?.cancel();
            _ttsTimer = Timer(const Duration(milliseconds: 1000), () {
              if (_isLive) {
                _ttsService.speakNicobarese(top.nicobareseLabel, englishWord: top.englishLabel);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[ARTranslator] Labeling error: $e');
    }
    _isDetecting = false;
  }

  InputImage? _toInputImage(CameraImage image) {
    if (_camera == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(_camera!.sensorOrientation)
        ?? InputImageRotation.rotation0deg;

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
      final term = englishLabel.toLowerCase();
      
      final exact = await db.query(
        'words',
        where: 'LOWER(english) = ?',
        whereArgs: [term],
        limit: 1,
      );
      if (exact.isNotEmpty && (exact.first['nicobarese'] ?? '').toString().isNotEmpty) {
        return exact.first['nicobarese'].toString();
      }
      
      final fuzzy = await db.query(
        'words',
        where: 'LOWER(english) LIKE ?',
        whereArgs: ['%$term%'],
        limit: 1,
      );
      if (fuzzy.isNotEmpty && (fuzzy.first['nicobarese'] ?? '').toString().isNotEmpty) {
        return fuzzy.first['nicobarese'].toString();
      }

      if (term.contains(' ')) {
        final lastWord = term.split(' ').last;
        final splitFuzzy = await db.query(
          'words',
          where: 'LOWER(english) LIKE ?',
          whereArgs: ['%$lastWord%'],
          limit: 1,
        );
        if (splitFuzzy.isNotEmpty && (splitFuzzy.first['nicobarese'] ?? '').toString().isNotEmpty) {
            return splitFuzzy.first['nicobarese'].toString();
        }
      }
    } catch (e) {
      debugPrint('[ARTranslator] Lookup error: $e');
    }
    return _capitalize(englishLabel);
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
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
    _imageLabeler.close();
    _ttsService.dispose();
    super.dispose();
  }

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
      scale: 1.05, // Slight zoom to avoid borders
      child: Center(
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.cyanAccent),
          SizedBox(height: 16),
          Text('INITIALIZING OPTICS...', style: TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', letterSpacing: 2)),
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
    // Top label is the focus, others are context
    final top = _detectedLabels.first;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main Target Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.center_focus_weak, color: Colors.cyanAccent, size: 32),
                const SizedBox(height: 12),
                Text(
                  top.nicobareseLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    top.englishLabel.toUpperCase(),
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
            ),
            child: const Text(
              'A.R. TRANSLATOR',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
          IconButton(
            onPressed: _toggleLive,
            icon: Icon(_isLive ? Icons.pause : Icons.play_arrow, color: _isLive ? Colors.white : Colors.cyanAccent),
            style: IconButton.styleFrom(backgroundColor: _isLive ? Colors.redAccent.withOpacity(0.8) : Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_detectedLabels.length <= 1) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, left: 16, right: 16, top: 24),
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
            child: Text('ENVIRONMENT ANALYSIS', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _detectedLabels.length - 1,
              itemBuilder: (context, index) {
                final label = _detectedLabels[index + 1];
                return GestureDetector(
                  onTap: () => _ttsService.speakNicobarese(label.nicobareseLabel, englishWord: label.englishLabel),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label.nicobareseLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          label.englishLabel,
                          style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
                        ),
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

class _ARLabel {
  final String englishLabel;
  final String nicobareseLabel;
  final double confidence;

  const _ARLabel({
    required this.englishLabel,
    required this.nicobareseLabel,
    required this.confidence,
  });
}

// ═══════════════════════════════════════════════
// UI EFFECTS: HUD SCANNERS & GRIDS
// ═══════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  final Animation<double> pulseAnimation;

  _GridPainter({required this.pulseAnimation}) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.05 + (pulseAnimation.value * 0.05))
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    
    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
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
    final boxSize = size.width * 0.7;
    final rect = Rect.fromCenter(center: center, width: boxSize, height: boxSize);

    // Draw Corner Brackets
    final bracketPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const cornerLength = 30.0;
    
    // Top Left
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, cornerLength), bracketPaint);
    // Top Right
    canvas.drawLine(rect.topRight, rect.topRight.translate(-cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, cornerLength), bracketPaint);
    // Bottom Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -cornerLength), bracketPaint);
    // Bottom Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(0, -cornerLength), bracketPaint);

    // Scan Line
    final scanLineY = rect.top + (rect.height * scanProgress);
    
    final scanLinePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    canvas.drawLine(
      Offset(rect.left, scanLineY),
      Offset(rect.right, scanLineY),
      scanLinePaint,
    );

    // Scan gradient
    final gradientRect = Rect.fromLTRB(rect.left, scanLineY - 40, rect.right, scanLineY);
    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, gradientRect.top),
        Offset(0, gradientRect.bottom),
        [Colors.cyanAccent.withOpacity(0.0), Colors.cyanAccent.withOpacity(0.3)],
      );
    
    canvas.drawRect(gradientRect, gradientPaint);
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) => oldDelegate.scanProgress != scanProgress;
}
