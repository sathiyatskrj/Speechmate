import 'package:flutter/material.dart';
import 'dart:math' as math;

class AiAssistantOverlay extends StatefulWidget {
  final bool isListening;
  final String currentText;
  final VoidCallback onMicPressed;
  final VoidCallback onClose;

  const AiAssistantOverlay({
    Key? key,
    required this.isListening,
    required this.currentText,
    required this.onMicPressed,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends State<AiAssistantOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Darken background
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 400,
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
                  // Magic AI Orb
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
                              Colors.cyanAccent,
                              Colors.blueAccent,
                              Colors.purpleAccent.withOpacity(0.5),
                            ],
                            stops: [0.2, 0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.6),
                              blurRadius: 30 + (10 * _pulseController.value),
                              spreadRadius: 5 + (5 * _pulseController.value),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Text Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.isListening 
                          ? "I am listening to you..." 
                          : (widget.currentText.isEmpty ? "Tap the mic to ask something!" : widget.currentText),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto', // Replace with custom font if available
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                        icon: Icons.close,
                        color: Colors.redAccent,
                        onTap: widget.onClose,
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: widget.onMicPressed,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isListening ? Colors.red : Colors.cyanAccent,
                            boxShadow: [
                              BoxShadow(
                                color: widget.isListening ? Colors.red.withOpacity(0.4) : Colors.cyan.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Icon(
                            widget.isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
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
