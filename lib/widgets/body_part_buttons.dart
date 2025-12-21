import 'package:flutter/material.dart';
import 'package:speechmate/widgets/tap_scale.dart';

class BodyPartButton extends StatelessWidget {
  final BodyPartItem item;
  final VoidCallback onTap;

  const BodyPartButton({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(item.image, height: 40, fit: BoxFit.contain),
          ),
          const SizedBox(height: 4),
          Text(item.name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class BodyPartItem {
  final String name;
  final String image;
  final String audio;

  BodyPartItem({required this.name, required this.image, required this.audio});
}
