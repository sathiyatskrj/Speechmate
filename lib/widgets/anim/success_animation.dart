import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

/// A reusable animated overlay for success/failure feedback.
/// Uses flutter_animate for smooth transitions and confetti for celebrations.
class SuccessAnimation extends StatefulWidget {
  final bool isSuccess;
  final String message;
  final VoidCallback? onDismiss;

  const SuccessAnimation({
    super.key,
    required this.isSuccess,
    required this.message,
    this.onDismiss,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.isSuccess) {
      _confettiController.play();
    }
    // Auto-dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Semi-transparent backdrop
        Container(color: Colors.black54),

        // Main feedback card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: widget.isSuccess
                ? const Color(0xFF1B5E20).withOpacity(0.95)
                : const Color(0xFFB71C1C).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (widget.isSuccess ? Colors.green : Colors.red).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              Icon(
                widget.isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 80,
                color: Colors.white,
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .shake(hz: widget.isSuccess ? 0 : 3, duration: 300.ms),

              const SizedBox(height: 16),

              // Message text
              Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
            ],
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 200.ms),

        // Confetti for success
        if (widget.isSuccess)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
      ],
    );
  }
}
