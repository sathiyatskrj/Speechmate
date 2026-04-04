import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/services/llm_manager_service.dart';
import 'package:speechmate/services/gemma_service.dart';
import 'dart:ui';

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

  // LLM State
  bool _isLlmDownloaded = false;
  bool _useAdvancedLlm = false;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _checkModelStatus();
    _initServices();
  }

  Future<void> _checkModelStatus() async {
    final status = await LlmManagerService().isModelDownloaded();
    if (mounted) setState(() => _isLlmDownloaded = status);
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
        if (_useAdvancedLlm && _isLlmDownloaded) {
           final genResult = await GemmaService().chat(_currentText);
           setState(() {
             _resultText = genResult;
             _confidence = 0.95; // LLM confidence is high for generation
             _isProcessing = false;
           });
        } else {
           final result = await _neuralEngine.predict(_currentText);
           setState(() {
             _resultText = result.text;
             _confidence = result.confidence;
             _isProcessing = false;
           });
        }

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

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    final service = LlmManagerService();
    
    service.progressStream.listen((progress) {
      if (mounted) setState(() => _downloadProgress = progress);
    });

    await service.startModelDownload();
    
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isLlmDownloaded = true;
        _useAdvancedLlm = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI Core Activated! Ready for Advanced Conversations."))
      );
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
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 520,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C).withOpacity(0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: _useAdvancedLlm ? Colors.purpleAccent.withOpacity(0.2) : Colors.cyanAccent.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 20),
                      _buildHeader(),
                      _buildMicSection(),
                      const Spacer(),
                      _buildFooter(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _useAdvancedLlm ? "SPEECHMATE ADVANCED" : "SPEECHMATE LITE",
                style: TextStyle(color: _useAdvancedLlm ? Colors.purpleAccent : Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const Text("AI Assistant Core", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          if (_isLlmDownloaded)
            Switch(
              value: _useAdvancedLlm,
              activeColor: Colors.purpleAccent,
              onChanged: (val) => setState(() => _useAdvancedLlm = val),
            )
          else if (!_isDownloading)
            TextButton.icon(
              onPressed: _handleDownload,
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text("UPGRADE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: Colors.amberAccent, backgroundColor: Colors.white.withOpacity(0.05)),
            )
        ],
      ),
    );
  }

  Widget _buildMicSection() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isDownloading)
            _buildDownloadUX()
          else ...[
            _buildBrainVisualizer(),
            const SizedBox(height: 30),
            _buildTranscriptionText(),
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadUX() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.cloud_download, color: Colors.amberAccent, size: 40),
          const SizedBox(height: 20),
          const Text("Syncing AI Core...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: _downloadProgress, backgroundColor: Colors.white10, color: Colors.amberAccent, borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 8),
          Text("${(_downloadProgress * 100).toInt()}% Remaining", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 20),
          const Text("Gemma 2B is an offline, heavy brain (~1.5GB). You can keep using Lite mode while we sync.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildBrainVisualizer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _isListening ? Colors.redAccent : (_useAdvancedLlm ? Colors.purpleAccent : Colors.cyanAccent),
                _isListening ? Colors.deepOrange : (_useAdvancedLlm ? Colors.deepPurple : Colors.blueAccent),
                Colors.black,
              ],
              stops: const [0.2, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: _isListening ? Colors.redAccent.withOpacity(0.6) : (_useAdvancedLlm ? Colors.purpleAccent.withOpacity(0.4) : Colors.cyanAccent.withOpacity(0.4)),
                blurRadius: 40 + (20 * _pulseController.value),
                spreadRadius: 5 + (10 * _pulseController.value),
              ),
            ],
          ),
          child: Icon(
            _isProcessing ? Icons.sync : (_useAdvancedLlm ? Icons.psychology : Icons.auto_awesome),
            color: Colors.white,
            size: 50,
          ).animate(onPlay: (controller) => controller.repeat())
           .rotate(duration: 2.seconds, begin: 0, end: _isProcessing ? 1 : 0),
        );
      },
    );
  }

  Widget _buildTranscriptionText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  style: TextStyle(
                    color: _useAdvancedLlm ? Colors.purpleAccent : Colors.cyanAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ).animate().slideY(begin: 0.1, end: 0).fadeIn(),
                if (!_useAdvancedLlm)
                  Text(
                    "Confidence: ${(_confidence * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButton(icon: Icons.close, color: Colors.white70, onTap: widget.onClose),
          const SizedBox(width: 40),
          GestureDetector(
            onTap: _onMicPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red : (_useAdvancedLlm ? Colors.purpleAccent : Colors.cyanAccent),
                boxShadow: [
                  BoxShadow(
                    color: _isListening ? Colors.red.withOpacity(0.4) : (_useAdvancedLlm ? Colors.purple.withOpacity(0.4) : Colors.cyan.withOpacity(0.4)),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
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
