import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:speechmate/services/progress_service.dart';
import 'dart:convert';
import '../widgets/background.dart';

class QrSyncScreen extends StatefulWidget {
  const QrSyncScreen({super.key});

  @override
  State<QrSyncScreen> createState() => _QrSyncScreenState();
}

class _QrSyncScreenState extends State<QrSyncScreen> {
  String? _syncPayload;

  @override
  void initState() {
    super.initState();
    _generatePayload();
  }

  Future<void> _generatePayload() async {
    final progressService = ProgressService();
    final wordsLearned = await progressService.getWordsLearnedCount();
    final streak = await progressService.getStreak();
    
    // Very simplified payload for QR limits (typically under 2KB)
    final payloadMap = {
       "dl": DateTime.now().millisecondsSinceEpoch,
       "w": wordsLearned,
       "s": streak,
       // we can add minimal flashcard hashes here
    };

    final rawJson = jsonEncode(payloadMap);
    final base64String = base64Encode(utf8.encode(rawJson));
    
    if (mounted) {
       setState(() {
          // Add custom URI scheme prefix to easily intent into SpeechMate
          _syncPayload = "speechmate://sync?p=$base64String";
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Device Sync"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Background(
        colors: const [Color(0xFF5f2c82), Color(0xFF49a09d)],
        child: SafeArea(
          child: Center(
            child: _syncPayload == null 
              ? const CircularProgressIndicator()
              : Container(
                  padding: const EdgeInsets.all(30),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       const Text("Scan from Another Device", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                       const SizedBox(height: 10),
                       const Text("Keep your progress across multiple devices by scanning this code.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                       const SizedBox(height: 30),
                       QrImageView(
                         data: _syncPayload!,
                         version: QrVersions.auto,
                         size: 200.0,
                         eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF5f2c82),
                         ),
                       ),
                       const SizedBox(height: 30),
                       ElevatedButton.icon(
                         onPressed: () => Navigator.pop(context),
                         icon: const Icon(Icons.check),
                         label: const Text("Done"),
                       )
                    ],
                  ),
              ),
          ),
        ),
      ),
    );
  }
}
