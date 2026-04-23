import 'package:flutter/material.dart';
import 'package:speechmate/services/model_downloader_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speechmate/providers/service_providers.dart';
import 'package:speechmate/core/app_colors.dart';

class AISetupScreen extends ConsumerStatefulWidget {
  const AISetupScreen({super.key});

  @override
  ConsumerState<AISetupScreen> createState() => _AISetupScreenState();
}

class _AISetupScreenState extends ConsumerState<AISetupScreen> {
  final ModelDownloaderService _downloader = ModelDownloaderService();
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final downloaded = await _downloader.isModelDownloaded();
    if (mounted) {
      setState(() {
        _isComplete = downloaded;
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      await _downloader.downloadModel((progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }
      });
      
      // Re-initialize the LLM service now that the model exists
      await ref.read(llmServiceProvider).initialize();
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isComplete = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Tutor Model Downloaded Successfully!'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("AI Tutor Engine Setup"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology_outlined, size: 100, color: Colors.cyanAccent),
              const SizedBox(height: 24),
              const Text(
                "Offline AI Tutor",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                "To enable completely offline dictionary-tuned AI translations and adaptive tutoring, you need to download the Neural Engine model (approx. 637 MB).",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              
              if (_isComplete) ...[
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
                const SizedBox(height: 16),
                const Text("Model is fully installed and ready!", style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              ] else if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white24,
                  color: Colors.cyanAccent,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 16),
                Text("${(_progress * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download, color: Colors.black),
                  label: const Text("Download AI Model", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
