import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';

class CameraTranslationScreen extends StatefulWidget {
  const CameraTranslationScreen({super.key});

  @override
  State<CameraTranslationScreen> createState() => _CameraTranslationScreenState();
}

class _CameraTranslationScreenState extends State<CameraTranslationScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  late ObjectDetector _objectDetector;
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();
  
  bool _isProcessing = false;
  List<Map<String, String>> _translationResults = [];
  String _detectedObject = "";
  
  @override
  void initState() {
    super.initState();
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
    _initializeCamera();
    _ttsService.init();
    _neuralEngine.init();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
         debugPrint("No cameras found");
         return;
      }
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    _objectDetector.close();
    super.dispose();
  }

  Future<void> _processImage(String path) async {
    setState(() {
      _isProcessing = true;
      _translationResults.clear();
      _detectedObject = "";
    });

    try {
      final inputImage = InputImage.fromFilePath(path);
      
      // 1. Try Object Detection first
      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);
      String objectName = "";
      if (objects.isNotEmpty && objects.first.labels.isNotEmpty) {
          objectName = objects.first.labels.first.text;
      }

      // 2. Try Text Recognition
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.trim().isNotEmpty) {
        // Book Scanner Mode: Split text into blocks or lines
        List<Map<String, String>> results = [];
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            String originalText = line.text.trim();
            if (originalText.isNotEmpty) {
               // Translate each line using offline Neural Engine
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
         // Object detection fallback
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
       await _processImage(image.path);
     } catch (e) {
       debugPrint("Capture error: $e");
     }
  }

  Future<void> _pickFromGallery() async {
     try {
       final ImagePicker picker = ImagePicker();
       final XFile? image = await picker.pickImage(source: ImageSource.gallery);
       if (image != null) {
          await _processImage(image.path);
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
         children: [
            Positioned.fill(
               child: CameraPreview(_cameraController!),
            ),
            Positioned(
               top: 40,
               left: 10,
               child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                  onPressed: () => Navigator.pop(context),
               )
            ),
            // Scanner overlay guide
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
            Positioned(
               top: MediaQuery.of(context).size.height / 2 - 120,
               left: 0, right: 0,
               child: const Text("Align text within the box", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
            ),
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
                           onTap: _captureAndTranslate,
                           child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 border: Border.all(color: Colors.cyanAccent, width: 4),
                                 color: Colors.white.withOpacity(0.3),
                              ),
                              child: _isProcessing 
                                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                                : const Center(child: Icon(Icons.camera_alt, color: Colors.white, size: 40)),
                           ),
                        ),
                        IconButton(
                           icon: const Icon(Icons.history, color: Colors.white, size: 30),
                           onPressed: () {}, // Optional: Add history later
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
