import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/tts_service.dart';

/// Offline AR Translator
/// Real-time camera stream → ML Kit Object Detection (on-device, 100% offline)
/// → Nicobarese dictionary lookup → live bounding box overlay + TTS
class ARTranslatorScreen extends StatefulWidget {
  const ARTranslatorScreen({super.key});

  @override
  State<ARTranslatorScreen> createState() => _ARTranslatorScreenState();
}

class _ARTranslatorScreenState extends State<ARTranslatorScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  CameraDescription? _camera;
  late ObjectDetector _objectDetector;
  final TtsService _ttsService = TtsService();

  bool _isDetecting = false;
  bool _isCameraReady = false;
  bool _isLive = true;

  List<_ARObject> _detectedObjects = [];
  String _lastSpoken = '';
  Timer? _ttsTimer;

  // Throttle: process one frame every 500ms
  DateTime _lastProcessed = DateTime.now();
  static const _throttleMs = 500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ttsService.init();
    _initDetector();
    _initCamera();
  }

  void _initDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _camera = cameras.first;
      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.medium,
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
    // Throttle
    final now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < _throttleMs) return;
    if (_isDetecting || !_isLive) return;
    _lastProcessed = now;
    _isDetecting = true;

    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) { _isDetecting = false; return; }

      final detectedList = await _objectDetector.processImage(inputImage);
      final arObjects = <_ARObject>[];

      for (final obj in detectedList) {
        if (obj.labels.isEmpty) continue;
        final label = obj.labels.first.text.toLowerCase();
        final confidence = obj.labels.first.confidence;
        if (confidence < 0.4) continue;

        // Look up Nicobarese translation from offline dictionary
        final translation = await _lookupNicobarese(label);

        arObjects.add(_ARObject(
          englishLabel: _capitalize(label),
          nicobareseLabel: translation,
          boundingBox: obj.boundingBox,
          confidence: confidence,
        ));
      }

      if (mounted) {
        setState(() => _detectedObjects = arObjects);
        // Auto-speak first detected object (debounced)
        if (arObjects.isNotEmpty) {
          final word = arObjects.first.nicobareseLabel;
          if (word != _lastSpoken && word != _capitalize(arObjects.first.englishLabel)) {
            _lastSpoken = word;
            _ttsTimer?.cancel();
            _ttsTimer = Timer(const Duration(milliseconds: 800), () {
              _ttsService.speakNicobarese(word, englishWord: arObjects.first.englishLabel);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[ARTranslator] Detection error: $e');
    }
    _isDetecting = false;
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _toInputImage(CameraImage image) {
    if (_camera == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(_camera!.sensorOrientation)
        ?? InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Android: NV21 = single-plane or we concat Y + UV
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

    // iOS: BGRA8888 = single plane
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
      // Try exact match first
      final exact = await db.query(
        'words',
        where: 'LOWER(english) = ?',
        whereArgs: [englishLabel.toLowerCase()],
        limit: 1,
      );
      if (exact.isNotEmpty && (exact.first['nicobarese'] ?? '').toString().isNotEmpty) {
        return exact.first['nicobarese'].toString();
      }
      // Try fuzzy LIKE match
      final fuzzy = await db.query(
        'words',
        where: 'LOWER(english) LIKE ?',
        whereArgs: ['%${englishLabel.toLowerCase()}%'],
        limit: 1,
      );
      if (fuzzy.isNotEmpty && (fuzzy.first['nicobarese'] ?? '').toString().isNotEmpty) {
        return fuzzy.first['nicobarese'].toString();
      }
    } catch (e) {
      debugPrint('[ARTranslator] Lookup error: $e');
    }
    return _capitalize(englishLabel); // Return English if no translation found
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _toggleLive() {
    setState(() {
      _isLive = !_isLive;
      _detectedObjects = [];
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ttsTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _objectDetector.close();
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
          // ── 1. CAMERA PREVIEW ──
          if (_isCameraReady && _cameraController != null)
            _buildCameraPreview()
          else
            _buildLoadingView(),

          // ── 2. AR OVERLAY (bounding boxes + labels) ──
          if (_isCameraReady && _detectedObjects.isNotEmpty)
            _buildAROverlay(),

          // ── 3. TOP BAR ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopBar(),
          ),

          // ── 4. BOTTOM PANEL (detected objects list) ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomPanel(),
          ),

          // ── 5. PAUSE INDICATOR ──
          if (!_isLive)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause_circle, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Paused', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: CameraPreview(_cameraController!),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent),
            SizedBox(height: 16),
            Text('Initializing AR Camera...', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildAROverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ARBoxPainter(
            objects: _detectedObjects,
            previewSize: _cameraController!.value.previewSize ?? const Size(480, 640),
            screenSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
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
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('🏝️ AR Translator', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Point camera at objects to translate', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleLive,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isLive ? Colors.cyanAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isLive ? Colors.cyanAccent : Colors.redAccent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isLive ? Icons.fiber_manual_record : Icons.pause, color: _isLive ? Colors.cyanAccent : Colors.redAccent, size: 14),
                  const SizedBox(width: 5),
                  Text(_isLive ? 'LIVE' : 'PAUSED', style: TextStyle(color: _isLive ? Colors.cyanAccent : Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, left: 16, right: 16, top: 24),
      child: _detectedObjects.isEmpty
          ? const Center(
              child: Text('🔍 Scanning for objects...', style: TextStyle(color: Colors.white38, fontSize: 14)),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DETECTED', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _detectedObjects.length,
                    itemBuilder: (context, index) {
                      final obj = _detectedObjects[index];
                      return GestureDetector(
                        onTap: () => _ttsService.speakNicobarese(obj.nicobareseLabel, englishWord: obj.englishLabel),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                obj.nicobareseLabel,
                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                obj.englishLabel,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.volume_up, color: Colors.white24, size: 11),
                                  const SizedBox(width: 3),
                                  Text('${(obj.confidence * 100).toInt()}%', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                ],
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

// ═══════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════
class _ARObject {
  final String englishLabel;
  final String nicobareseLabel;
  final Rect boundingBox;
  final double confidence;

  const _ARObject({
    required this.englishLabel,
    required this.nicobareseLabel,
    required this.boundingBox,
    required this.confidence,
  });
}

// ═══════════════════════════════════════════════
// CUSTOM PAINTER: AR Bounding Boxes + Labels
// ═══════════════════════════════════════════════
class _ARBoxPainter extends CustomPainter {
  final List<_ARObject> objects;
  final Size previewSize;
  final Size screenSize;

  const _ARBoxPainter({
    required this.objects,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = screenSize.width / previewSize.height;
    final scaleY = screenSize.height / previewSize.width;

    for (final obj in objects) {
      final rect = Rect.fromLTRB(
        obj.boundingBox.left * scaleX,
        obj.boundingBox.top * scaleY,
        obj.boundingBox.right * scaleX,
        obj.boundingBox.bottom * scaleY,
      );

      // Glow border
      final glowPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), glowPaint);

      // Solid border
      final borderPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), borderPaint);

      // Corner accents
      _drawCorners(canvas, rect);

      // Label background
      final labelText = '${obj.nicobareseLabel}  •  ${obj.englishLabel}';
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${obj.nicobareseLabel}  ',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: obj.englishLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: screenSize.width * 0.7);

      final labelBgRect = Rect.fromLTWH(
        rect.left,
        rect.top - 28,
        textPainter.width + 20,
        26,
      );

      final bgPaint = Paint()..color = const Color(0xCC000000);
      canvas.drawRRect(RRect.fromRectAndRadius(labelBgRect, const Radius.circular(6)), bgPaint);

      textPainter.paint(canvas, Offset(rect.left + 10, rect.top - 24));
    }
  }

  void _drawCorners(Canvas canvas, Rect rect) {
    const len = 14.0;
    const strokeWidth = 3.0;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, len), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight.translate(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, len), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -len), paint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(0, -len), paint);
  }

  @override
  bool shouldRepaint(_ARBoxPainter oldDelegate) =>
      oldDelegate.objects != objects;
}
