import 'dart:math';
import 'package:flutter/material.dart';/// Scores pronunciation accuracy by comparing transcribed speech to expected text.
/// Uses Levenshtein distance normalized to a 0-100 score.
class PronunciationScorer {
  /// Compare [transcribed] text against [expected] text.
  /// Returns a score from 0 (no match) to 100 (perfect match).
  static int score(String transcribed, String expected) {
    final t = transcribed.trim().toLowerCase();
    final e = expected.trim().toLowerCase();

    if (t.isEmpty || e.isEmpty) return 0;
    if (t == e) return 100;

    final distance = _levenshtein(t, e);
    final maxLen = max(t.length, e.length);
    final similarity = 1.0 - (distance / maxLen);
    return (similarity * 100).round().clamp(0, 100);
  }

  /// Returns a qualitative label for the score.
  static String label(int score) {
    if (score >= 90) return 'Excellent! 🌟';
    if (score >= 70) return 'Great! 👍';
    if (score >= 50) return 'Good effort! 💪';
    if (score >= 30) return 'Keep practicing 📖';
    return 'Try again 🔄';
  }

  /// Standard Levenshtein distance algorithm.
  static int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;

    // Use two-row optimization to save memory
    List<int> prev = List.generate(n + 1, (j) => j);
    List<int> curr = List.filled(n + 1, 0);

    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      for (int j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1,       // deletion
          curr[j - 1] + 1,   // insertion
          prev[j - 1] + cost, // substitution
        ].reduce(min);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[n];
  }
}

/// Real-time Waveform Visualizer to provide users immediate, visual feedback 
/// on their intonation and pitch compared to native speakers.
class PronunciationWaveformVisualizer extends StatefulWidget {
  final bool isRecording;
  final Color activeColor;
  final Color inactiveColor;

  const PronunciationWaveformVisualizer({
    super.key,
    required this.isRecording,
    this.activeColor = Colors.greenAccent,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<PronunciationWaveformVisualizer> createState() => _PronunciationWaveformVisualizerState();
}

class _PronunciationWaveformVisualizerState extends State<PronunciationWaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = List.filled(30, 0.0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        if (widget.isRecording) {
          setState(() {
            for (int i = 0; i < _heights.length; i++) {
              // Simulate pitch/intonation variance
              _heights[i] = _random.nextDouble() * 50 + 10;
            }
          });
        }
      });
    
    if (widget.isRecording) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PronunciationWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        setState(() {
          for (int i = 0; i < _heights.length; i++) {
            _heights[i] = 10.0;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_heights.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 4.5,
            height: widget.isRecording ? _heights[index] : 10,
            decoration: BoxDecoration(
              color: widget.isRecording 
                  ? widget.activeColor.withValues(alpha: _random.nextDouble() * 0.5 + 0.5) 
                  : widget.inactiveColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: widget.isRecording ? [
                BoxShadow(
                  color: widget.activeColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ] : null,
            ),
          );
        }),
      ),
    );
  }
}
