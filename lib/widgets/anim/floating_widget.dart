import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double distance;

  const FloatingWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.distance = 10.0,
  }) : super(key: key);

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: widget.duration
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -widget.distance, end: widget.distance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
