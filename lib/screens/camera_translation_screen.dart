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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speechmate/providers/service_providers.dart';
import 'package:speechmate/widgets/ar_overlay_controller.dart';
import 'package:speechmate/data/ar_mock_data.dart';

class CameraTranslationScreen extends ConsumerStatefulWidget {
  const CameraTranslationScreen({super.key});

  @override
  ConsumerState<CameraTranslationScreen> createState() => _CameraTranslationScreenState();
}

class _CameraTranslationScreenState extends ConsumerState<CameraTranslationScreen> {
  CameraController? _cameraController;
  CameraDescription? _camera;
  
  late TextRecognizer _textRecognizer;
  late ObjectDetector _objectDetector;
  // Services will be obtained via Riverpod in build/process methods where needed
  // using ref.read(...) instead of direct instantiation.
  
  bool _isProcessing = false;
  List<Map<String, String>> _translationResults = [];
  String _detectedObject = "";
  
  // Live mode
  bool _isLiveMode = false;
  bool _isDetecting = false;
  DateTime _lastProcessed = DateTime.now();
  static const _throttleMs = 500;
  List<TranslatedTextBlock> _liveBlocks = [];
  bool _flashlightOn = false;
  String _allRecognizedText = '';

  // Static/Capture Mode
  String? _capturedImagePath;
  Size? _staticImageSize;
  List<TranslatedTextBlock> _staticBlocks = [];

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
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
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
      
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint("Focus mode not supported: $e");
      }

      // Enable auto-exposure for better OCR in varying light
      try {
        await _cameraController!.setExposureMode(ExposureMode.auto);
      } catch (_) {}
      
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
      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);

      List<TranslatedTextBlock> newBlocks = [];
      final StringBuffer allText = StringBuffer();

      // Process Objects
      for (DetectedObject obj in objects) {
        String objectName = "";
        double objectConfidence = 0;
        for (final lbl in obj.labels) {
          if (lbl.confidence > objectConfidence) {
            objectConfidence = lbl.confidence;
            objectName = lbl.text;
          }
        }
        
        if (objectName.isNotEmpty && objectConfidence > 0.5) {
           final result = await ref.read(neuralEngineProvider).predict(objectName);
           final info = ARMockData.getObjectInfo(objectName);
           newBlocks.add(TranslatedTextBlock(
             rect: obj.boundingBox,
             original: objectName,
             translation: result.text.isNotEmpty ? result.text : "Translation unavailable",
             confidence: objectConfidence,
             isObject: true,
             info: info,
           ));
           allText.writeln(objectName);
        }
      }
      
      // Process Text
      for (TextBlock block in recognizedText.blocks) {
        String blockText = _cleanOcrText(block.text);
        allText.writeln(blockText);
        if (blockText.isNotEmpty && blockText.length > 1) {
          final result = await ref.read(neuralEngineProvider).predict(blockText);
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
           _allRecognizedText = allText.toString().trim();
        });
      }
    } catch (e) {
      debugPrint("Live OCR error: $e");
    }
    _isDetecting = false;
  }

  /// Clean OCR output for better translation accuracy
  String _cleanOcrText(String raw) {
    String text = raw.replaceAll('\n', ' ').trim();
    // Normalize common OCR misreads
    text = text.replaceAll(RegExp(r'[|]'), 'I');
    text = text.replaceAll(RegExp(r'[`´]'), "'");
    // Remove stray special characters but keep basic punctuation
    text = text.replaceAll(RegExp(r"[^\w\s.,!?'-]"), '');
    // Collapse multiple spaces
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return text;
  }

  InputImage? _toInputImage(CameraImage image) {
    if (_camera == null || _cameraController == null) return null;

    final sensorOrientation = _camera!.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      var deviceOrientation = orientations[_cameraController!.value.deviceOrientation] ?? 0;
      var rotationCompensation = (sensorOrientation + deviceOrientation) % 360;
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    // Use nv21 as fallback on Android if raw value parsing fails
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? 
                  (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);

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
      _staticBlocks.clear();
    });

    try {
      final inputImage = InputImage.fromFilePath(path);
      
      // Decode image to get size for AR overlay
      final bytes = await File(path).readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      _staticImageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      
      // Try Object Detection
      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);
      String objectName = "";
      double objectConfidence = 0;
      for (final obj in objects) {
        for (final lbl in obj.labels) {
          if (lbl.confidence > objectConfidence) {
            objectConfidence = lbl.confidence;
            objectName = lbl.text;
          }
        }
        if (objectName.isNotEmpty && objectConfidence > 0.5) {
           final result = await ref.read(neuralEngineProvider).predict(objectName);
           final info = ARMockData.getObjectInfo(objectName);
           _staticBlocks.add(TranslatedTextBlock(
             rect: obj.boundingBox,
             original: objectName,
             translation: result.text.isNotEmpty ? result.text : "Translation unavailable",
             confidence: objectConfidence,
             isObject: true,
             info: info,
           ));
        }
      }

      // Try Text Recognition
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final StringBuffer allRaw = StringBuffer();
      
      if (recognizedText.text.trim().isNotEmpty) {
        List<Map<String, String>> results = [];
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            String originalText = _cleanOcrText(line.text);
            allRaw.writeln(originalText);
            if (originalText.isNotEmpty) {
               final result = await ref.read(neuralEngineProvider).predict(originalText);
               results.add({
                 "original": originalText,
                 "translation": result.text.isNotEmpty ? result.text : "Translation unavailable",
               });
               if (result.text.isNotEmpty) {
                 _staticBlocks.add(TranslatedTextBlock(
                   rect: line.boundingBox,
                   original: originalText,
                   translation: result.text,
                 ));
               }
            }
          }
        }
        setState(() {
          _detectedObject = objectName.isNotEmpty ? "Also detected: $objectName" : "";
          _translationResults = results;
          _allRecognizedText = allRaw.toString().trim();
        });
      } else if (objectName.isNotEmpty) {
         final result = await ref.read(neuralEngineProvider).predict(objectName);
         setState(() {
           _detectedObject = "Detected Object: $objectName (${(objectConfidence * 100).toStringAsFixed(0)}%)";
           _translationResults = [{
              "original": objectName,
              "translation": result.text.isNotEmpty ? result.text : "Translation unavailable",
           }];
           _allRecognizedText = objectName;
         });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text or objects recognized. Try again.')),
          );
        }
      }
      
      // Simulate scanning delay for better UX
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (_staticBlocks.isNotEmpty && mounted) {
        _showResultSheet();
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
       setState(() { _capturedImagePath = image.path; });
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
          setState(() { _capturedImagePath = image.path; });
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
                      color: Color(0xFF1E1E2C),
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
                         // Copy All Raw Text button
                         if (_allRecognizedText.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(bottom: 12),
                             child: OutlinedButton.icon(
                               icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.cyanAccent),
                               label: const Text('Copy All Recognized Text', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                               style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.cyanAccent)),
                               onPressed: () {
                                 Clipboard.setData(ClipboardData(text: _allRecognizedText));
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text('Text copied to clipboard'), backgroundColor: Colors.cyanAccent),
                                 );
                               },
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
                                   Row(
                                     children: [
                                       const Expanded(child: Text("Original Text", style: TextStyle(color: Colors.white54, fontSize: 12))),
                                       GestureDetector(
                                         onTap: () {
                                           Clipboard.setData(ClipboardData(text: item['original'] ?? ''));
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                                           );
                                         },
                                         child: const Icon(Icons.copy, color: Colors.white38, size: 16),
                                       ),
                                     ],
                                   ),
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
                                         onPressed: () => ref.read(ttsServiceProvider).speakNicobarese(item['translation'] ?? '', englishWord: item['original']),
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
               child: _capturedImagePath != null && !_isLiveMode
                   ? Image.file(File(_capturedImagePath!), fit: BoxFit.contain)
                   : CameraPreview(_cameraController!),
            ),
            
            // Live Text Overlay Layer
            if (_isLiveMode && _liveBlocks.isNotEmpty)
              AROverlayController(
                liveBlocks: _liveBlocks,
                imageSize: Size(_cameraController!.value.previewSize!.height, _cameraController!.value.previewSize!.width),
                screenSize: screenSize,
              ),

            // Static/Captured Image Overlay Layer
            if (!_isLiveMode && _staticBlocks.isNotEmpty && !_isProcessing && _staticImageSize != null)
              AROverlayController(
                liveBlocks: _staticBlocks,
                imageSize: _staticImageSize!,
                screenSize: screenSize,
              ),

            // Scanning Effect Overlay
            if (_isProcessing)
              Positioned.fill(
                 child: Stack(
                   children: [
                      Container(color: Colors.black54),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.cyanAccent),
                            const SizedBox(height: 16),
                            const Text("SCANNING AND DETECTING...", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2.0, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                          ],
                        ),
                      )
                   ]
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
                      onPressed: () {
                         if (_capturedImagePath != null && !_isLiveMode) {
                            setState(() { _capturedImagePath = null; _staticBlocks.clear(); });
                         } else {
                            Navigator.pop(context);
                         }
                      },
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.black54,
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
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
                         setState(() { _isLiveMode = true; _capturedImagePath = null; _staticBlocks.clear(); });
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
            if (!_isLiveMode && _capturedImagePath == null)
              Center(
                 child: Container(
                    width: 300,
                    height: 150,
                    decoration: BoxDecoration(
                       border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 2),
                       borderRadius: BorderRadius.circular(12),
                       color: Colors.cyanAccent.withValues(alpha: 0.05),
                    ),
                 ),
              ),
            if (!_isLiveMode && _capturedImagePath == null)
              Positioned(
                 top: MediaQuery.of(context).size.height / 2 - 120,
                 left: 0, right: 0,
                 child: const Text("Align text within the box", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
              ),
            
            // Bottom Controls
            if (_capturedImagePath == null)
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
                        colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.0)],
                     )
                  ),
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                        IconButton(
                           icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                           onPressed: _pickFromGallery,
                        ),
                        // Flashlight toggle
                        IconButton(
                           icon: Icon(
                             _flashlightOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
                             color: _flashlightOn ? Colors.amberAccent : Colors.white,
                             size: 28,
                           ),
                           onPressed: () async {
                             if (_cameraController == null) return;
                             try {
                               _flashlightOn = !_flashlightOn;
                               await _cameraController!.setFlashMode(
                                 _flashlightOn ? FlashMode.torch : FlashMode.off,
                               );
                               setState(() {});
                             } catch (_) {}
                           },
                        ),
                        GestureDetector(
                           onTap: _isLiveMode ? null : _captureAndTranslate,
                           child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 border: Border.all(color: _isLiveMode ? Colors.grey : Colors.cyanAccent, width: 4),
                                 color: Colors.white.withValues(alpha: 0.3),
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
            else
              // Actions for captured image
              Positioned(
                 bottom: 30,
                 left: 0,
                 right: 0,
                 child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          label: const Text("Retake", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          onPressed: () {
                             setState(() {
                               _capturedImagePath = null;
                               _staticBlocks.clear();
                             });
                          },
                       ),
                       const SizedBox(width: 20),
                       ElevatedButton.icon(
                          icon: const Icon(Icons.list, color: Colors.black),
                          label: const Text("View Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          onPressed: _showResultSheet,
                       ),
                    ],
                 )
              )
         ],
      )
    );
  }
}
