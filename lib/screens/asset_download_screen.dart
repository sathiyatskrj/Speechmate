import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Post-installation download screen for required assets that are NOT
/// bundled in the APK to keep the install size at ~80 MB.
///
/// Downloads:
///   1. Whisper Base model (ggml-base.bin ~141 MB) — required for voice features
///
/// This screen is shown after onboarding and blocks navigation until
/// the user either downloads or skips (voice features disabled).
class AssetDownloadScreen extends StatefulWidget {
  final Widget nextScreen;
  const AssetDownloadScreen({super.key, required this.nextScreen});

  @override
  State<AssetDownloadScreen> createState() => _AssetDownloadScreenState();
}

class _AssetDownloadScreenState extends State<AssetDownloadScreen> {
  final Dio _dio = Dio();

  // Download state
  bool _isChecking = true;
  bool _isDownloading = false;
  bool _isComplete = false;
  bool _hasFailed = false;
  double _progress = 0.0;
  String _statusText = 'Checking installed assets...';
  String _errorText = '';

  // Asset definitions
  static const String _whisperModelName = 'ggml-tiny.bin';
  // Hugging Face direct download URL for Whisper Tiny multilingual GGML
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin';
  static const int _expectedSizeBytes = 73000000; // ~73 MB

  @override
  void initState() {
    super.initState();
    _checkAssets();
  }

  Future<String> _getModelPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$_whisperModelName';
  }

  Future<void> _checkAssets() async {
    try {
      final path = await _getModelPath();
      final file = File(path);
      if (file.existsSync() && file.lengthSync() > _expectedSizeBytes * 0.9) {
        // Already downloaded
        if (mounted) {
          setState(() {
            _isChecking = false;
            _isComplete = true;
            _statusText = 'All assets ready!';
          });
          // Auto-navigate after brief delay
          await Future.delayed(const Duration(milliseconds: 800));
          _navigateNext();
        }
      } else {
        if (mounted) {
          setState(() {
            _isChecking = false;
            _statusText = 'Voice engine model required';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _statusText = 'Voice engine model required';
        });
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasFailed = false;
      _errorText = '';
      _progress = 0.0;
      _statusText = 'Downloading Whisper Base model...';
    });

    try {
      final path = await _getModelPath();

      await _dio.download(
        _whisperModelUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _progress = received / total;
              final mbReceived = (received / 1024 / 1024).toStringAsFixed(1);
              final mbTotal = (total / 1024 / 1024).toStringAsFixed(0);
              _statusText = 'Downloading... $mbReceived / $mbTotal MB';
            });
          }
        },
      );

      // Verify download
      final file = File(path);
      if (file.existsSync() && file.lengthSync() > _expectedSizeBytes * 0.9) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isComplete = true;
            _statusText = 'Download complete!';
          });
          await Future.delayed(const Duration(milliseconds: 600));
          _navigateNext();
        }
      } else {
        throw Exception('Downloaded file appears corrupt');
      }
    } catch (e) {
      debugPrint('[AssetDownload] Download failed: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _hasFailed = true;
          _errorText = e.toString().contains('SocketException')
              ? 'No internet connection. Connect to Wi-Fi and try again.'
              : 'Download failed. Please check your connection and retry.';
          _statusText = 'Download failed';
        });
      }
    }
  }

  void _skipDownload() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Skip Voice Engine?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Without the voice model, Voice Translator and speech features will not work.\n\nYou can download it later from Settings.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateNext();
            },
            child: const Text('Skip', style: TextStyle(color: Colors.amberAccent)),
          ),
        ],
      ),
    );
  }

  void _navigateNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isComplete
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : _hasFailed
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isComplete ? const Color(0xFF10B981) : const Color(0xFF0D9488))
                          .withOpacity(0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Icon(
                  _isComplete
                      ? Icons.check_rounded
                      : _hasFailed
                          ? Icons.error_outline_rounded
                          : Icons.download_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),

              const SizedBox(height: 36),

              // Title
              Text(
                _isComplete
                    ? 'All Set!'
                    : _isChecking
                        ? 'Checking Assets'
                        : 'Download Required',
                style: GoogleFonts.outfit(
                  fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              // Description
              Text(
                _isComplete
                    ? 'Voice engine is ready. Teachers and students can use all classroom voice features offline.'
                    : 'The voice translation engine (~73 MB) needs a one-time download for classroom speech features. After that, everything works offline — perfect for island schools.',
                style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF94A3B8), height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              // Progress area
              if (_isDownloading || _isComplete) ...[
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _isComplete ? 1.0 : _progress,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isComplete ? const Color(0xFF10B981) : const Color(0xFF0D9488),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Error message
              if (_hasFailed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorText,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFFCA5A5), height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(flex: 1),

              // Action buttons
              if (!_isChecking && !_isComplete) ...[
                // Download button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _startDownload,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _isDownloading
                          ? '${(_progress * 100).toStringAsFixed(0)}%'
                          : _hasFailed
                              ? 'Retry Download'
                              : 'Download Voice Engine',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Skip button
                TextButton(
                  onPressed: _isDownloading ? null : _skipDownload,
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 1),

              // Size info
              Text(
                'Requires ~73 MB storage • Wi-Fi recommended • Educational Edition',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF475569)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
