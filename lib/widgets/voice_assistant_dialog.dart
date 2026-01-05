import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle/AssetBundle
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'ai_assistant_overlay.dart';

class VoiceAssistantDialog extends StatefulWidget {
  const VoiceAssistantDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // Allow full screen height interactions
      backgroundColor: Colors.transparent,
      enableDrag: false, // Prevent accidental dismissal while recording
      builder: (context) => const VoiceAssistantDialog(),
    );
  }

  @override
  State<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends State<VoiceAssistantDialog> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  String _aiText = "Listening..."; // Initial State

  @override
  void initState() {
    super.initState();
    // Auto-start recording when opened
    _startRecording();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<String> _getModelPath() async {
     final Directory appDocDir = await getApplicationDocumentsDirectory();
     final String modelPath = '${appDocDir.path}/ggml-tiny.en.bin';
     
     if (!File(modelPath).existsSync()) {
       try {
         final ByteData data = await DefaultAssetBundle.of(context).load('assets/models/ggml-tiny.en.bin');
         final List<int> bytes = data.buffer.asUint8List();
         await File(modelPath).writeAsBytes(bytes);
       } catch (e) {
         debugPrint("Error copying model: $e");
       }
     }
     return modelPath;
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/temp_voice_search.wav';
        
        // Ensure clean slate
        if (File(filePath).existsSync()) {
            File(filePath).deleteSync();
        }

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), 
          path: filePath
        );
        
        setState(() {
          _isRecording = true;
          _aiText = "Listening...";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _aiText = "Mic Error: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() { _isRecording = false; _aiText = "Thinking..."; });

      if (path != null) {
        final modelPath = await _getModelPath();
        final text = await WhisperService().transcribe(modelPath, path);
        
        if (text.startsWith("Error")) {
           setState(() => _aiText = "Oops! I didn't catch that.");
        } else {
           final cleanText = text.replaceAll("[BLANK_AUDIO]", "").trim();
           if (cleanText.isEmpty) {
               setState(() => _aiText = "I heard silence...");
           } else {
               setState(() => _aiText = cleanText);
               // Wait a moment then return result
               await Future.delayed(const Duration(seconds: 1));
               if (mounted) {
                   Navigator.pop(context, cleanText);
               }
           }
        }
      }
    } catch (e) {
       setState(() => _aiText = "Error: $e");
    }
  }
  
  void _onMicTap() {
      if (_isRecording) {
          _stopRecording();
      } else {
          _startRecording();
      }
  }

  @override
  Widget build(BuildContext context) {
    // We use AiAssistantOverlay as the UI content
    return AiAssistantOverlay(
        isListening: _isRecording, 
        currentText: _aiText, 
        onMicPressed: _onMicTap, 
        onClose: () => Navigator.pop(context) // Cancel
    );
  }
}
