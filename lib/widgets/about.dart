import 'package:flutter/material.dart';

class InfoButton extends StatelessWidget {
  const InfoButton({super.key});

  // Constant information for all screens
  static const String _imagePath = 'assets/icons/branding.png';
  static const String _aboutText =
      'This application helps you learn and practice multiple languages. '
      'Select your preferred language to get started with your learning journey.';
  static const String _createdBy = 'T Sathiya Moorthy';
  static const String _developedBy = 'Pratik Bairagi';

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
      ),
      onPressed: () {
        _showInfoDialog(context);
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // Dim background ONLY
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white, // ✅ important fix
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 93, 139, 139),
                  Color.fromARGB(255, 66, 123, 123),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),

                // Image
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: screenHeight * 0.20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE0E0E0), // fallback background
                  ),
                  clipBehavior: Clip.antiAlias, // ensures rounded corners
                  child: Image.asset(
                    _imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'group image',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Us',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // better contrast
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _aboutText,
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Created by....$_createdBy',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      Text(
                        'Developed by....$_developedBy',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
