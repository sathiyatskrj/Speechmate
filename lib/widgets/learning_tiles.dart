import 'package:flutter/material.dart';
import 'tap_scale.dart';

class LearningTiles extends StatelessWidget {
  final String word;
  final List<Color> gradient;
  final Widget? navigateTo;

  const LearningTiles({
    super.key,
    required this.word,
    required this.gradient,
    this.navigateTo,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return TapScale(
      onTap: () {
        if (navigateTo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigateTo!),
          );
        }
      },
      child: Container(
        width: size.width * 0.40,
        height: size.height * 0.12,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            word,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
