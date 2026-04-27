import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/background.dart';

class VoiceVaultScreen extends StatefulWidget {
  const VoiceVaultScreen({super.key});

  @override
  State<VoiceVaultScreen> createState() => _VoiceVaultScreenState();
}

class _VoiceVaultScreenState extends State<VoiceVaultScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  String? _recordedPath;
  bool _isPlaying = false;
  
  // Contribution list
  List<String> _contributions = [];
  bool _isElderMode = false;
  
  // Community Verification items
  final List<Map<String, dynamic>> _pendingReviews = [
    {"title": "Recording: Tōt (Jungle)", "upvotes": 12, "downvotes": 2},
    {"title": "Recording: Pū-cö (Island)", "upvotes": 4, "downvotes": 1},
    {"title": "Recording: Kunö (Student)", "upvotes": 45, "downvotes": 0}
  ];

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contributions = prefs.getStringList('voice_vault_contributions') ?? [];
    });
  }

  Future<void> _saveContribution(String word) async {
    final prefs = await SharedPreferences.getInstance();
    _contributions.add(word);
    await prefs.setStringList('voice_vault_contributions', _contributions);
    setState(() {});
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/temp_vault_recording.wav';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav), 
          path: filePath
        );
        
        setState(() {
          _isRecording = true;
          _recordedPath = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
    } catch (e) {
       debugPrint('[VoiceVault] Recording stop error: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedPath != null) {
      setState(() => _isPlaying = true);
      await _audioPlayer.play(DeviceFileSource(_recordedPath!));
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  void _submitRecording() {
    if (_recordedPath == null) return;
    
    // Simulate upload
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading
      _saveContribution("Recording #${_contributions.length + 1} - ${DateTime.now().toString().substring(0, 16)}");
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Thank You! 🏆"),
          content: const Text("Your voice has been added to the Nicobarese AI Dataset. You are helping preserve the language!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _recordedPath = null);
              },
              child: const Text("Awesome"),
            )
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Voice Vault 🎙️", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Background(
        colors: const [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildModeToggle(),
                const SizedBox(height: 20),
                _buildHeaderCard(),
                const SizedBox(height: 20),
                
                // Dynamic Area
                Expanded(
                  child: _isElderMode ? _buildElderVerificationView() : _buildRecordingView(),
                ),
                
                if (!_isElderMode) ...[
                  const SizedBox(height: 20),
                  const Align(
                     alignment: Alignment.centerLeft,
                     child: Text("Recent Contributions", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _contributions.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white.withValues(alpha: 0.05),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                            title: Text(_contributions[_contributions.length - 1 - index], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            trailing: const Text("+10 XP", style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                          ),
                        );
                      },
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
         if (_recordedPath == null) ...[
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(_isRecording ? 40 : 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.redAccent : Colors.cyanAccent.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                  boxShadow: [
                    if (_isRecording)
                      BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)
                  ]
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 50,
                  color: _isRecording ? Colors.white : Colors.cyanAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? "Listening... Tap to Stop" : "Tap to Contribute",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
         ] else ...[
            // Review State
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("Recording Captured!", style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle_fill, size: 50, color: Colors.white),
                        onPressed: _playRecording,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, size: 50, color: Colors.redAccent),
                        onPressed: () => setState(() => _recordedPath = null),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitRecording,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Submit to Dataset"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            )
         ]
      ],
    );
  }

  Widget _buildElderVerificationView() {
    if (_pendingReviews.isEmpty) {
      return const Center(child: Text("All caught up! No pending reviews.", style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      itemCount: _pendingReviews.length,
      itemBuilder: (context, index) {
        final review = _pendingReviews[index];
        return Card(
          color: Colors.white.withValues(alpha: 0.1),
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up, size: 14, color: Colors.greenAccent),
                        const SizedBox(width: 4),
                        Text("${review['upvotes']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 5),
                const Text("Pending Community Validation (P2P)", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.play_circle_fill, size: 40, color: Colors.cyanAccent),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Playing P2P audio preview...")));
                        },
                    ),
                    IconButton(
                        icon: const Icon(Icons.thumb_down, size: 35, color: Colors.redAccent),
                        onPressed: () {
                           setState(() {
                             _pendingReviews[index]['downvotes']++;
                           });
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You downvoted this pronunciation.")));
                        },
                    ),
                    IconButton(
                        icon: const Icon(Icons.thumb_up, size: 35, color: Colors.greenAccent),
                        onPressed: () {
                           setState(() {
                             _pendingReviews[index]['upvotes']++;
                             if (_pendingReviews[index]['upvotes'] >= 50) {
                               // Simulate auto-verify
                               _pendingReviews.removeAt(index);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recording reached 50 upvotes and is verified!")));
                               return;
                             }
                           });
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You upvoted this pronunciation!")));
                        },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return Row(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         ChoiceChip(
           label: const Text("Contribute"),
           selected: !_isElderMode,
           onSelected: (val) => setState(() => _isElderMode = false),
           selectedColor: Colors.cyanAccent,
           labelStyle: TextStyle(color: !_isElderMode ? Colors.black : Colors.white),
           backgroundColor: Colors.white.withValues(alpha: 0.1),
         ),
         const SizedBox(width: 15),
         ChoiceChip(
           label: const Text("Community Validation"),
           selected: _isElderMode,
           onSelected: (val) => setState(() => _isElderMode = true),
           selectedColor: Colors.purpleAccent,
           labelStyle: TextStyle(color: _isElderMode ? Colors.white : Colors.white),
           backgroundColor: Colors.white.withValues(alpha: 0.1),
         ),
       ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade900, Colors.deepPurple.shade900]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.diversity_3, color: Colors.cyanAccent, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isElderMode ? "Verify Contributions 🛡️" : "Help Us Grow! 🌱", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(_isElderMode ? "Listen to community P2P recordings and UPVOTE them for accuracy." : "Record words to train our AI and preserve the Nicobarese language forever.", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
