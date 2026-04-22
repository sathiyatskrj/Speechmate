import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'dart:ui' as ui;

class CameraTranslationScreen extends StatefulWidget {
  const CameraTranslationScreen({super.key});

  @override
  State<CameraTranslationScreen> createState() => _CameraTranslationScreenState();
}

class _CameraTranslationScreenState extends State<CameraTranslationScreen> {
  CameraController? _cameraController;
  CameraDescription? _camera;
  
  late TextRecognizer _textRecognizer;
  late ObjectDetector _objectDetector;
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();
  
  bool _isProcessing = false;
  List<Map<String, String>> _translationResults = [];
  String _detectedObject = "";
  
  // Live mode
  bool _isLiveMode = false;
  bool _isDetecting = false;
  DateTime _lastProcessed = DateTime.now();
  static const _throttleMs = 800;
  List<TranslatedTextBlock> _liveBlocks = [];

  // Multi-language OCR Support
  final Map<String, TextRecognitionScript> _supportedLanguages = {
    "English": TextRecognitionScript.latin,
    "Hindi": TextRecognitionScript.devanagiri,
    "Bengali (Beta)": TextRecognitionScript.devanagiri,
    "Tamil (Beta)": TextRecognitionScript.latin,
    "Telugu (Beta)": TextRecognitionScript.latin,
    "Chinese": TextRecognitionScript.chinese,
    "Japanese": TextRecognitionScript.japanese,
    "Korean": TextRecognitionScript.korean,
  };
  String _selectedLanguage = "English";

  void _onLanguageChanged(String? newLang) {
    if (newLang == null || newLang == _selectedLanguage) return;
    setState(() {
      _selectedLanguage = newLang;
      _textRecognizer.close();
      _textRecognizer = TextRecognizer(script: _supportedLanguages[_selectedLanguage]!);
    });
  }
  
  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: _supportedLanguages[_selectedLanguage]!);
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
    _ttsService.init();
    _neuralEngine.init();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);

      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
      
      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _textRecognizer.close();
    _objectDetector.close();
    super.dispose();
  }

  // Live Stream Processing
  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isLiveMode) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < _throttleMs) return;
    if (_isDetecting) return;
    _lastProcessed = now;
    _isDetecting = true;

    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) { _isDetecting = false; return; }

      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      List<TranslatedTextBlock> newBlocks = [];
      
      for (TextBlock block in recognizedText.blocks) {
        String blockText = block.text.replaceAll('\n', ' ').trim();
        if (blockText.isNotEmpty && blockText.length > 2) {
          final result = await _neuralEngine.predict(blockText);
          if (result.text.isNotEmpty) {
             newBlocks.add(TranslatedTextBlock(
               rect: block.boundingBox,
               original: blockText,
               translation: result.text,
             ));
          }
        }
      }
      
      if (mounted && _isLiveMode) {
        setState(() {
           _liveBlocks = newBlocks;
        });
      }
    } catch (e) {
      debugPrint("Live OCR error: $e");
    }
    _isDetecting = false;
  }

  InputImage? _toInputImage(CameraImage image) {
    if (_camera == null) return null;
    final rotation = InputImageRotationValue.fromRawValue(_camera!.sensorOrientation) ?? InputImageRotation.rotation0deg;
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

  // Static Processing
  Future<void> _processStaticImage(String path) async {
    setState(() {
      _isProcessing = true;
      _translationResults.clear();
      _detectedObject = "";
    });

    try {
      final inputImage = InputImage.fromFilePath(path);
      
      // Try Object Detection
      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);
      String objectName = "";
      if (objects.isNotEmpty && objects.first.labels.isNotEmpty) {
          objectName = objects.first.labels.first.text;
      }

      // Try Text Recognition
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.trim().isNotEmpty) {
        List<Map<String, String>> results = [];
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            String originalText = line.text.trim();
            if (originalText.isNotEmpty) {
               final result = await _neuralEngine.predict(originalText);
               results.add({
                 "original": originalText,
                 "translation": result.text.isNotEmpty ? result.text : "Translation unavailable",
               });
            }
          }
        }
        setState(() {
          _detectedObject = "";
          _translationResults = results;
        });
        _showResultSheet();
      } else if (objectName.isNotEmpty) {
         final result = await _neuralEngine.predict(objectName);
         setState(() {
           _detectedObject = "Detected Object: $objectName";
           _translationResults = [{
              "original": objectName,
              "translation": result.text.isNotEmpty ? result.text : "Translation unavailable",
           }];
         });
         _showResultSheet();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text or objects recognized. Try again.')),
          );
        }
      }
    } catch (e) {
       debugPrint("Processing Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _captureAndTranslate() async {
     if (_cameraController == null || !_cameraController!.value.isInitialized) return;
     if (_isProcessing) return;

     try {
       final XFile image = await _cameraController!.takePicture();
       await _processStaticImage(image.path);
     } catch (e) {
       debugPrint("Capture error: $e");
     }
  }

  Future<void> _pickFromGallery() async {
     try {
       final ImagePicker picker = ImagePicker();
       final XFile? image = await picker.pickImage(source: ImageSource.gallery);
       if (image != null) {
          await _processStaticImage(image.path);
       }
     } catch (e) {
       debugPrint("Picker error: $e");
     }
  }

  void _showResultSheet() {
      showModalBottomSheet(
         context: context,
         backgroundColor: Colors.transparent,
         isScrollControlled: true,
         builder: (context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Container(
                   decoration: const BoxDecoration(
                      color: Color(0xFF1E1E2C), // Premium surface color
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                   ),
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                   child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                         Center(
                           child: Container(
                             width: 40, height: 4,
                             margin: const EdgeInsets.only(bottom: 20),
                             decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                           ),
                         ),
                         if (_detectedObject.isNotEmpty) ...[
                            Text(_detectedObject, style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                         ],
                         Expanded(
                           child: ListView.separated(
                             controller: controller,
                             itemCount: _translationResults.length,
                             separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 32),
                             itemBuilder: (context, index) {
                               final item = _translationResults[index];
                               return Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   const Text("Original Text", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                   const SizedBox(height: 4),
                                   Text(item['original'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                                   const SizedBox(height: 12),
                                   const Text("Nicobarese Translation", style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                                   const SizedBox(height: 4),
                                   Row(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Expanded(
                                         child: Text(item['translation'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                       ),
                                       IconButton(
                                         icon: const Icon(Icons.volume_up, color: Colors.cyanAccent),
                                         onPressed: () => _ttsService.speakNicobarese(item['translation'] ?? '', englishWord: item['original']),
                                       )
                                     ],
                                   ),
                                 ],
                               );
                             },
                           ),
                         ),
                      ]
                   )
                );
              }
            );
         }
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
         backgroundColor: Colors.black,
         appBar: AppBar(
             backgroundColor: Colors.transparent,
             elevation: 0,
             leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
             ),
         ),
         body: Center(
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const CircularProgressIndicator(color: Colors.cyanAccent),
                   const SizedBox(height: 20),
                   const Text("Initializing Camera...", style: TextStyle(color: Colors.white)),
                   const SizedBox(height: 40),
                   ElevatedButton.icon(
                       icon: const Icon(Icons.photo_library),
                       label: const Text("Select from Gallery instead"),
                       onPressed: _pickFromGallery,
                   )
                ]
             )
         )
      );
    }

    final Size screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
         children: [
            Positioned.fill(
               child: CameraPreview(_cameraController!),
            ),
            
            // Live Text Overlay Layer
            if (_isLiveMode && _liveBlocks.isNotEmpty)
              Positioned.fill(
                 child: CustomPaint(
                    painter: LiveTextOverlayPainter(
                       blocks: _liveBlocks,
                       imageSize: Size(_cameraController!.value.previewSize!.height, _cameraController!.value.previewSize!.width), // Swap due to portrait
                       screenSize: screenSize,
                    ),
                 ),
              ),

            // Top Bar
            Positioned(
               top: 40,
               left: 10,
               right: 10,
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                      onPressed: () => Navigator.pop(context),
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.black54,
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                     ),
                     child: DropdownButtonHideUnderline(
                       child: DropdownButton<String>(
                         value: _selectedLanguage,
                         dropdownColor: Colors.black87,
                         icon: const Icon(Icons.language, color: Colors.cyanAccent, size: 20),
                         style: const TextStyle(color: Colors.white, fontSize: 14),
                         onChanged: _onLanguageChanged,
                         items: _supportedLanguages.keys.map((lang) {
                           return DropdownMenuItem<String>(
                             value: lang,
                             child: Padding(
                               padding: const EdgeInsets.only(right: 8.0),
                               child: Text(lang),
                             ),
                           );
                         }).toList(),
                       ),
                     ),
                   ),
                 ],
               )
            ),
            
            // Mode Toggle
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.cyanAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                         setState(() { _isLiveMode = false; _liveBlocks.clear(); });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isLiveMode ? Colors.cyanAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text("Capture", style: TextStyle(color: !_isLiveMode ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                         setState(() { _isLiveMode = true; });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isLiveMode ? Colors.cyanAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text("Live AR", style: TextStyle(color: _isLiveMode ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Scanner overlay guide (Capture Mode)
            if (!_isLiveMode)
              Center(
                 child: Container(
                    width: 300,
                    height: 150,
                    decoration: BoxDecoration(
                       border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                       borderRadius: BorderRadius.circular(12),
                       color: Colors.cyanAccent.withOpacity(0.05),
                    ),
                 ),
              ),
            if (!_isLiveMode)
              Positioned(
                 top: MediaQuery.of(context).size.height / 2 - 120,
                 left: 0, right: 0,
                 child: const Text("Align text within the box", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
              ),
            
            // Bottom Controls
            Positioned(
               bottom: 0,
               left: 0,
               right: 0,
               child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                     gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.0)],
                     )
                  ),
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                        IconButton(
                           icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                           onPressed: _pickFromGallery,
                        ),
                        GestureDetector(
                           onTap: _isLiveMode ? null : _captureAndTranslate, // Disabled in live mode
                           child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 border: Border.all(color: _isLiveMode ? Colors.grey : Colors.cyanAccent, width: 4),
                                 color: Colors.white.withOpacity(0.3),
                              ),
                              child: _isProcessing 
                                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                                : Center(child: Icon(Icons.camera_alt, color: _isLiveMode ? Colors.grey : Colors.white, size: 40)),
                           ),
                        ),
                        IconButton(
                           icon: const Icon(Icons.history, color: Colors.white, size: 30),
                           onPressed: () {}, 
                        ),
                     ],
                  ),
               )
            )
         ],
      )
    );
  }
}

class TranslatedTextBlock {
  final Rect rect;
  final String original;
  final String translation;

  TranslatedTextBlock({required this.rect, required this.original, required this.translation});
}

class LiveTextOverlayPainter extends CustomPainter {
  final List<TranslatedTextBlock> blocks;
  final Size imageSize;
  final Size screenSize;

  LiveTextOverlayPainter({required this.blocks, required this.imageSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;

    for (var block in blocks) {
      // Scale bounding box to screen dimensions
      final double left = block.rect.left * scaleX;
      final double top = block.rect.top * scaleY;
      final double width = block.rect.width * scaleX;
      final double height = block.rect.height * scaleY;
      
      final Rect scaledRect = Rect.fromLTWH(left, top, width, height);

      // Draw background box
      final Paint bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), bgPaint);

      // Draw border
      final Paint borderPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), borderPaint);

      // Draw Text
      final TextSpan span = TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        text: block.translation,
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout(minWidth: width, maxWidth: width);
      
      // Center vertically within the block
      final double textY = top + (height - tp.height) / 2;
      tp.paint(canvas, Offset(left, textY));
    }
  }

  @override
  bool shouldRepaint(LiveTextOverlayPainter oldDelegate) => true;
}
