import 'package:flutter/material.dart';
import 'tap_scale.dart';

class CommonWordCard extends StatelessWidget {
  final String word;
  final String emoji;
  final List<Color> gradient;
  final ValueChanged<String> onWordSelected;

  const CommonWordCard({
    super.key,
    required this.word,
    required this.emoji,
    required this.gradient,
    required this.onWordSelected,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return TapScale(
      onTap: () => onWordSelected(word),
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
            "$emoji $word",
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
