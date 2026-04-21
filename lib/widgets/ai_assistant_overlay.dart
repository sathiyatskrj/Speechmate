import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/core/app_colors.dart';

class AiAssistantOverlay extends StatefulWidget {
  final ValueChanged<String> onResult;
  final VoidCallback onClose;

  const AiAssistantOverlay({
    Key? key,
    required this.onResult,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends State<AiAssistantOverlay> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WhisperService _whisperService = WhisperService();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusText = "Initializing Whisper AI...";
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final ready = await _whisperService.initialize();
    if (mounted) {
      setState(() {
        _statusText = ready ? "Tap to speak" : "Whisper AI unavailable";
      });
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (!_whisperService.isAvailable) return;

    if (_isRecording) {
      // STOP RECORDING
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusText = "Processing audio...";
      });

      try {
        final path = await _audioRecorder.stop();
        if (path != null && File(path).existsSync()) {
          final transcribedText = await _whisperService.transcribe(path);
          if (mounted) {
            if (transcribedText.trim().isNotEmpty) {
              widget.onResult(transcribedText.trim());
            } else {
              setState(() {
                _isProcessing = false;
                _statusText = "Could not hear anything. Try again.";
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _statusText = "Audio recording failed.";
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusText = "Error: $e";
          });
        }
      }
    } else {
      // START RECORDING
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _audioFilePath = '${dir.path}/whisper_query_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1, sampleRate: 16000),
          path: _audioFilePath!,
        );

        setState(() {
          _isRecording = true;
          _statusText = "Listening...";
        });
      } else {
        setState(() {
          _statusText = "Microphone permission denied.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isRecording && !_isProcessing) widget.onClose();
      },
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap from closing
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: AppColors.studentAccent.withOpacity(0.3), blurRadius: 20)
                ],
              ),
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 32)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2.seconds),
                  const SizedBox(height: 15),
                  const Text(
                    'Whisper AI Search',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isRecording ? Colors.pinkAccent : Colors.white70,
                      fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Mic Button
                  GestureDetector(
                    onTap: _isProcessing ? null : _toggleRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isProcessing 
                            ? Colors.grey.withOpacity(0.3) 
                            : _isRecording 
                                ? Colors.pinkAccent 
                                : AppColors.studentAccent,
                        boxShadow: [
                          if (_isRecording)
                            BoxShadow(color: Colors.pinkAccent.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                        ],
                      ),
                      child: _isProcessing 
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic_rounded, 
                              color: Colors.white, 
                              size: 40
                            ),
                    ),
                  ).animate(target: _isRecording ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                  
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: (_isRecording || _isProcessing) ? null : widget.onClose,
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
