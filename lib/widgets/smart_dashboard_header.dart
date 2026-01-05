import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
// import 'package:speechmate/services/dictionary_service.dart'; // Unused
// import 'package:speechmate/services/whisper_service.dart'; // Moved to Dialog
// import 'package:record/record.dart'; // Moved to Dialog
import '../core/app_colors.dart';
import 'search_bar.dart';
import 'voice_assistant_dialog.dart';

// Unified Header Component to remove duplication
// Handles: Title, Subtitle, Search, Mic, Whisper Logic
class SmartDashboardHeader extends StatefulWidget {
  final bool isTeacher;
  final Function(String query) onSearch;
  final Function() onClear;
  final TextEditingController searchController;

  const SmartDashboardHeader({
    super.key,
    required this.isTeacher,
    required this.onSearch,
    required this.onClear,
    required this.searchController,
  });

  @override
  State<SmartDashboardHeader> createState() => _SmartDashboardHeaderState();
}

class _SmartDashboardHeaderState extends State<SmartDashboardHeader> {
  // --- VOICE LOGIC ---
  Future<void> _onMicTap() async {
       final result = await VoiceAssistantDialog.show(context);
       if (result != null && result.isNotEmpty) {
           setState(() {
               widget.searchController.text = result;
           });
           widget.onSearch(result);
       }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTeacher = widget.isTeacher;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     isTeacher ? "Teacher Panel" : "SpeechMate", 
                     style: theme.textTheme.displayLarge?.copyWith(fontSize: isTeacher ? 32 : 36)
                   ),
                   Text(
                     "Where language barriers end.", 
                     style: theme.textTheme.bodyMedium?.copyWith(
                       color: isTeacher ? AppColors.teacherAccent : Colors.purpleAccent,
                       fontStyle: FontStyle.italic
                     )
                   ),
                 ],
               ),
               if (isTeacher)
                 IconButton(
                   icon: const Icon(Icons.logout, color: Colors.white70),
                   onPressed: () => Navigator.pop(context),
                 )
             ],
           ),
           const SizedBox(height: 25),
           Search(
              controller: widget.searchController,
              onSearch: () => widget.onSearch(widget.searchController.text),
              onClear: widget.onClear,
              onMicTap: _onMicTap,
           ),
        ],
      ),
    );
  }
}
