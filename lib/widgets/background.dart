import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const Background({
    super.key,
    required this.colors,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
