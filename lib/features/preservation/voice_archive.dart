import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

class VoiceArchiveScreen extends StatefulWidget {
  const VoiceArchiveScreen({super.key});

  @override
  State<VoiceArchiveScreen> createState() => _VoiceArchiveScreenState();
}

class _VoiceArchiveScreenState extends State<VoiceArchiveScreen> with SingleTickerProviderStateMixin {
  int _totalWordsPreserved = 2431;
  int _contributors = 187;
  bool _isRecording = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 1)
    )..repeat(reverse: true);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalWordsPreserved = prefs.getInt('archive_count') ?? 2431;
    });
  }

  Future<void> _incrementStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalWordsPreserved++;
    });
    prefs.setInt('archive_count', _totalWordsPreserved);
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    if (!_isRecording) {
      // Stopped recording
      _showSuccessDialog();
      _incrementStats();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green), 
          SizedBox(width: 10),
          Text("Voice Archived")
        ]),
        content: const Text("Thank you for contributing to the digital heritage of Nicobar. Your voice has been securely stored."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Done"))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text("Community Voice Archive"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             // LIVE COUNTER CARD
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, offset: const Offset(0,5))],
               ),
               child: Column(
                 children: [
                   const Text("WORDS PRESERVED FOREVER", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                   const SizedBox(height: 10),
                   Text(
                     "$_totalWordsPreserved", 
                     style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)
                   ),
                   const Divider(color: Colors.white24, height: 30),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.people, color: Colors.white, size: 16),
                       const SizedBox(width: 8),
                       Text("$_contributors Native Speakers Contributed", style: const TextStyle(color: Colors.white, fontSize: 14)),
                     ],
                   )
                 ],
               ),
             ),
             
             const Spacer(),

             // RECORDING VISUALIZER (Simulated)
             if (_isRecording)
               SizedBox(
                 height: 100,
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: List.generate(10, (index) {
                     return AnimatedBuilder(
                       animation: _pulseController,
                       builder: (context, child) {
                         double height = 20 + Random().nextInt(50) * _pulseController.value;
                         return Container(
                           margin: const EdgeInsets.symmetric(horizontal: 4),
                           width: 8,
                           height: height,
                           decoration: BoxDecoration(
                             color: Colors.greenAccent,
                             borderRadius: BorderRadius.circular(10),
                           ),
                         );
                       },
                     );
                   }),
                 ),
               )
             else 
               const Center(
                 child: Text(
                   "Tap mic to preserve a word",
                   style: TextStyle(color: Colors.white54),
                 ),
               ),

             const Spacer(),

             // RECORD BUTTON
             Center(
               child: GestureDetector(
                 onTap: _toggleRecording,
                 child: AnimatedContainer(
                   duration: const Duration(milliseconds: 300),
                   height: _isRecording ? 90 : 80,
                   width: _isRecording ? 90 : 80,
                   decoration: BoxDecoration(
                     color: _isRecording ? Colors.red : Colors.cyan,
                     shape: BoxShape.circle,
                     boxShadow: [
                       BoxShadow(
                         color: _isRecording ? Colors.redAccent.withOpacity(0.5) : Colors.cyanAccent.withOpacity(0.5),
                         blurRadius: 20,
                         spreadRadius: 5
                       )
                     ],
                   ),
                   child: Icon(
                     _isRecording ? Icons.stop : Icons.mic, 
                     color: Colors.white, 
                     size: 36
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 40),
           ],
        ),
      ),
    );
  }
}
