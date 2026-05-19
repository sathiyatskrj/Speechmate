import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/widgets/background.dart';

class StoryRadioScreen extends StatefulWidget {
  const StoryRadioScreen({super.key});

  @override
  State<StoryRadioScreen> createState() => _StoryRadioScreenState();
}

class _StoryRadioScreenState extends State<StoryRadioScreen> {
  final DatabaseManager _db = DatabaseManager.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioRecorder? _audioRecorder;

  // Store subscriptions so we can cancel them in dispose()
  final List<StreamSubscription> _subscriptions = [];

  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;

  int? _playingStoryId;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadStories();

    _subscriptions.add(
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      }),
    );

    _subscriptions.add(
      _audioPlayer.onDurationChanged.listen((newDuration) {
        if (mounted) setState(() => _duration = newDuration);
      }),
    );

    _subscriptions.add(
      _audioPlayer.onPositionChanged.listen((newPosition) {
        if (mounted) setState(() => _position = newPosition);
      }),
    );

    _subscriptions.add(
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
            _playingStoryId = null;
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _audioPlayer.dispose();
    _audioRecorder?.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    final results = await _db.queryAll('stories');
    setState(() {
      _stories = results;
      _isLoading = false;
    });
  }

  Future<void> _playStory(Map<String, dynamic> story) async {
    if (_playingStoryId == story['id']) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } else {
      await _audioPlayer.stop();
      setState(() => _playingStoryId = story['id']);
      
      final source = story['audio_path'].startsWith('assets/') 
          ? AssetSource(story['audio_path'].replaceFirst('assets/', ''))
          : DeviceFileSource(story['audio_path']);
          
      await _audioPlayer.play(source);
    }
  }

  void _showRecordDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController storytellerController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C3E50),
              title: const Text("Record Oral History 🎙️", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Story Title",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: storytellerController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Storyteller Name (Elder)",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      if (_isRecording) {
                        final path = await _audioRecorder?.stop();
                        setDialogState(() => _isRecording = false);
                        
                        if (path != null && titleController.text.isNotEmpty) {
                          Navigator.pop(statefulContext); // Close dialog
                          
                          // Save to DB
                          final db = await _db.database;
                          await db.insert('stories', {
                            'title': titleController.text.trim(),
                            'storyteller': storytellerController.text.trim().isEmpty ? 'Anonymous Elder' : storytellerController.text.trim(),
                            'audio_path': path,
                            'duration_seconds': 0, // In a real app we'd measure length
                            'timestamp': DateTime.now().millisecondsSinceEpoch,
                          });
                          
                          _loadStories();
                          if (statefulContext.mounted) {
                            ScaffoldMessenger.of(statefulContext).showSnackBar(const SnackBar(content: Text("Story preserved for future generations!")));
                          }
                        }
                      } else {
                        // Recreate recorder for fresh state
                        _audioRecorder?.dispose();
                        _audioRecorder = AudioRecorder();
                        if (await _audioRecorder!.hasPermission()) {
                          final dir = await getApplicationDocumentsDirectory();
                          final path = '${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}.wav';
                          await _audioRecorder!.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
                          setDialogState(() => _isRecording = true);
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(_isRecording ? 30 : 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.redAccent : Colors.cyan.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.cyan, width: 2),
                      ),
                      child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 40, color: _isRecording ? Colors.white : Colors.cyan),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_isRecording ? "Recording..." : "Tap to Record", style: const TextStyle(color: Colors.cyan)),
                ],
              ),
              actions: [
                if (!_isRecording)
                  TextButton(
                    onPressed: () => Navigator.pop(statefulContext),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                  )
              ],
            );
          }
        );
      }
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Oral History Radio 📻", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordDialog,
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text("Record a Tale", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amberAccent,
      ).animate().slideY(begin: 1, end: 0, duration: 500.ms),
      body: Stack(
        children: [
          const Background(colors: [Color(0xFF3E2723), Color(0xFF1B5E20)]), // Earthy brown/green
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
                : _stories.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("No stories recorded yet. Be the first to preserve a piece of history!", 
                            textAlign: TextAlign.center, 
                            style: TextStyle(color: Colors.white70, fontSize: 16)),
                        )
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                        itemCount: _stories.length,
                        itemBuilder: (context, index) {
                          final story = _stories[index];
                          final isPlaying = _playingStoryId == story['id'];
                          
                          return Card(
                            color: Colors.white.withValues(alpha: isPlaying ? 0.2 : 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: isPlaying ? Colors.amberAccent : Colors.transparent, width: 2),
                            ),
                            margin: const EdgeInsets.only(bottom: 15),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.waves, color: Colors.amberAccent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          story['title'] ?? 'Untitled Tale',
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text("Told by: ${story['storyteller'] ?? 'Elder'}", style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isPlaying && _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                          size: 50,
                                          color: isPlaying ? Colors.amberAccent : Colors.white,
                                        ),
                                        onPressed: () => _playStory(story),
                                      ).animate(target: isPlaying && _isPlaying ? 1 : 0).scale(end: const Offset(1.1, 1.1)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: isPlaying
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Slider(
                                                  activeColor: Colors.amberAccent,
                                                  inactiveColor: Colors.white24,
                                                  min: 0.0,
                                                  max: _duration.inSeconds.toDouble(),
                                                  value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                                                  onChanged: (val) {
                                                    _audioPlayer.seek(Duration(seconds: val.toInt()));
                                                  },
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(_formatDuration(_position), style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                                                      Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Container(
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.white12,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
