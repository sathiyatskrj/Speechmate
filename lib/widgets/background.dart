import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry? padding;

  const Background({
    super.key,
    required this.child,
    this.colors = const [],
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 400;
    
    // Responsive padding based on screen size
    final responsivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 12 : (isMediumScreen ? 16 : 20),
      vertical: isSmallScreen ? 30 : (isMediumScreen ? 40 : 50),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: responsivePadding,
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
