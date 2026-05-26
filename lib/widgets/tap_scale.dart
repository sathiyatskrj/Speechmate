import 'package:flutter/material.dart';

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.92,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {

  double _scale = 1;

  void _animate() async {
    setState(() => _scale = widget.scaleFactor);
    await Future.delayed(widget.duration);
    setState(() => _scale = 1);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap == null ? null : _animate,
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
