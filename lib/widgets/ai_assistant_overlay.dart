import 'package:flutter/material.dart';

class AiAssistantOverlay extends StatelessWidget {
  final ValueChanged<String> onResult;
  final VoidCallback onClose;

  const AiAssistantOverlay({
    Key? key,
    required this.onResult,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => onResult('Test result'),
                child: const Text('Simulate AI Response'),
              ),
              TextButton(
                onPressed: onClose,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
