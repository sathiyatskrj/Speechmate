import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry padding;

  const Background({
    super.key,
    required this.child,
      this.colors = const [],
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
