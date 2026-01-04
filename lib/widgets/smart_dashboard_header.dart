import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:speechmate/services/dictionary_service.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:record/record.dart';
import '../core/app_colors.dart';
import 'search_bar.dart';
import 'ai_assistant_overlay.dart';

// Unified Header Component to remove duplication
// Handles: Title, Subtitle, Search, Mic, Whisper Logic
class SmartDashboardHeader extends StatefulWidget {
  final bool isTeacher;
  final Function(String query) onSearch;
  final Function() onClear;
  final TextEditingController searchController;

  const SmartDashboardHeader({
    super.key,
    required this.isTeacher,
    required this.onSearch,
    required this.onClear,
    required this.searchController,
  });

  @override
  State<SmartDashboardHeader> createState() => _SmartDashboardHeaderState();
}

class _SmartDashboardHeaderState extends State<SmartDashboardHeader> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  // AI Mic State
  bool _isRecording = false;
  bool _showAiOverlay = false;
  String _aiText = "";

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  // --- WHISPER LOGIC (Encapsulated) ---
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
        final String filePath = '${appDocDir.path}/temp_recording_${widget.isTeacher ? "teacher" : "student"}.wav';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), 
          path: filePath
        );
        
        setState(() {
          _isRecording = true;
          _showAiOverlay = true; 
          _aiText = "Listening...";
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mic Error: $e")));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() { _isRecording = false; _aiText = "Thinking..."; });

      if (path != null) {
        final modelPath = await _getModelPath();
        final text = await WhisperService().transcribe(modelPath, path);
        
        if (text.startsWith("Error")) {
           setState(() => _aiText = "Oops! I didn't catch that.");
        } else {
           final cleanText = text.replaceAll("[BLANK_AUDIO]", "").trim();
           setState(() {
               _aiText = cleanText.isEmpty ? "I heard silence..." : cleanText;
               widget.searchController.text = cleanText; 
           });
           
           if (cleanText.isNotEmpty) {
               await Future.delayed(const Duration(seconds: 2));
               if (mounted) {
                   setState(() => _showAiOverlay = false);
                   widget.onSearch(cleanText);
               }
           }
        }
      }
    } catch (e) {
       setState(() => _aiText = "Error: $e");
    }
  }
  
  void _onMicTap() => _isRecording ? _stopRecording() : _startRecording();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTeacher = widget.isTeacher;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         isTeacher ? "Teacher Panel" : "SpeechMate", 
                         style: theme.textTheme.displayLarge?.copyWith(fontSize: isTeacher ? 32 : 36)
                       ),
                       Text(
                         "Where language barriers end.", 
                         style: theme.textTheme.bodyMedium?.copyWith(
                           color: isTeacher ? AppColors.teacherAccent : Colors.purpleAccent,
                           fontStyle: FontStyle.italic
                         )
                       ),
                     ],
                   ),
                   // Optional: Profile or logout for teacher, handled by parent usually but can add visual flair here
                   if (isTeacher)
                     IconButton(
                       icon: const Icon(Icons.logout, color: Colors.white70),
                       onPressed: () => Navigator.pop(context),
                     )
                 ],
               ),
               const SizedBox(height: 25),
               Search(
                  controller: widget.searchController,
                  onSearch: () => widget.onSearch(widget.searchController.text),
                  onClear: widget.onClear,
                  onMicTap: _onMicTap,
               ),
            ],
          ),
        ),

        // AI Overlay (Embedded)
        if (_showAiOverlay)
            Positioned.fill(
              child: AiAssistantOverlay(
                  isListening: _isRecording,
                  currentText: _aiText,
                  onMicPressed: _onMicTap,
                  onClose: () => setState(() => _showAiOverlay = false),
              ),
            )
      ],
    );
  }
}
