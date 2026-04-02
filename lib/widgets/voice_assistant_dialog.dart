import 'package:flutter/material.dart';
import 'ai_assistant_overlay.dart';

class VoiceAssistantDialog extends StatefulWidget {
  const VoiceAssistantDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      enableDrag: false, 
      builder: (context) => const VoiceAssistantDialog(),
    );
  }

  @override
  State<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends State<VoiceAssistantDialog> {
  @override
  Widget build(BuildContext context) {
    // Both Search (STT) and AI Assistant now use the dual-mode Overlay
    // This dialog now acts as a modal container for the AI assistant
    return AiAssistantOverlay(
        onResult: (text) => Navigator.pop(context, text),
        onClose: () => Navigator.pop(context) // Cancel
    );
  }
}
