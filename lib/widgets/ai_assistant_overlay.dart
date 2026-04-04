import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/core/app_strings.dart';

class AiAssistantOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String transcription)? onResult; // If provided, returns result and closes

  const AiAssistantOverlay({
    Key? key,
    required this.onClose,
    this.onResult,
  }) : super(key: key);

  @override
  State<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends State<AiAssistantOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final WhisperService _whisperService = WhisperService();
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();
  late AudioRecorder _audioRecorder;
  String? _audioFilePath;

  bool _isListening = false;
  bool _isProcessing = false;
  String _currentText = "";
  String _resultText = "";
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initServices();
  }

  Future<void> _initServices() async {
    _audioRecorder = AudioRecorder();
    await _whisperService.initialize();
    await _neuralEngine.init();
    await _ttsService.init();
    
    // Auto-start listening if provided as a "Return Result" bot
    if (widget.onResult != null) {
        _startListening();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder.dispose();
    _ttsService.stop();
    super.dispose();
  }

  void _onMicPressed() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _audioFilePath = '${dir.path}/speechmate_temp_record.wav';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _audioFilePath!,
      );

      setState(() {
        _isListening = true;
        _currentText = AppStrings.get('recordingAudio');
        _resultText = "";
        _isProcessing = false;
      });
    }
  }

  Future<void> _stopListening() async {
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _currentText = AppStrings.get('transcribingWhisper');
    });

    await _audioRecorder.stop();

    if (_audioFilePath != null) {
      final text = await _whisperService.transcribe(_audioFilePath!);
      setState(() {
        _currentText = text;
      });

      if (_currentText.isNotEmpty) {
        if (widget.onResult != null) {
            // Mode: Search/STT
            widget.onResult!(_currentText);
            return;
        }

        // Mode: AI Conversation
        final result = await _neuralEngine.predict(_currentText);
        setState(() {
          _resultText = result.text;
          _confidence = result.confidence;
          _isProcessing = false;
        });

        if (_resultText.isNotEmpty) {
          await _ttsService.speakNicobarese(_resultText, englishWord: _currentText.split(' ').first);
        }
      } else {
        setState(() => _isProcessing = false);
      }
    } else {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _isListening ? Colors.redAccent : Colors.cyanAccent,
                              _isListening ? Colors.deepOrange : Colors.blueAccent,
                              _isListening ? Colors.purpleAccent.withOpacity(0.5) : Colors.purpleAccent.withOpacity(0.5),
                            ],
                            stops: const [0.2, 0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isListening ? Colors.redAccent.withOpacity(0.6) : Colors.cyanAccent.withOpacity(0.6),
                              blurRadius: 30 + (20 * _pulseController.value),
                              spreadRadius: 5 + (10 * _pulseController.value),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isProcessing ? Icons.sync : Icons.auto_awesome,
                          color: Colors.white,
                          size: 50,
                        ).animate(onPlay: (controller) => controller.repeat())
                         .rotate(duration: 2.seconds, begin: 0, end: _isProcessing ? 1 : 0),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          _currentText.isNotEmpty ? _currentText : AppStrings.get('tapMicToRecord'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        if (_resultText.isNotEmpty && !_isListening && !_isProcessing) 
                          Column(
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                _resultText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Confidence: ${(_confidence * 100).toStringAsFixed(0)}%",
                                style: TextStyle(color: Colors.white24, fontSize: 10),
                              ),
                            ],
                          ),
                        if (_currentText.isEmpty && !_isListening && !_isProcessing && _resultText.isEmpty)
                          const Text(
                            "Tap the mic to ask something!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(icon: Icons.close, color: Colors.redAccent, onTap: widget.onClose),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: _onMicPressed,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening ? Colors.red : Colors.cyanAccent,
                            boxShadow: [
                              BoxShadow(
                                color: _isListening ? Colors.red.withOpacity(0.4) : Colors.cyan.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
