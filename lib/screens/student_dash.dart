import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/dictionary_service.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/background.dart';
import 'package:speechmate/widgets/search_bar.dart';
import 'package:speechmate/widgets/translation_card.dart';
import 'package:speechmate/widgets/gamification_header.dart';
import 'package:speechmate/widgets/ai_assistant_overlay.dart';

// Screen Imports
import 'package:speechmate/screens/number_page.dart';
import 'package:speechmate/screens/nature_page.dart';
import 'package:speechmate/screens/feelings_page.dart';
import 'package:speechmate/screens/mybody_part.dart'; // BodyPartsScreen
import 'package:speechmate/screens/games/games_hub_screen.dart';
import 'package:speechmate/screens/animals_page.dart';
import 'package:speechmate/screens/magic_words_page.dart';
import 'package:speechmate/screens/family_page.dart';
import 'package:speechmate/screens/community_screen.dart';

class StudentDash extends StatefulWidget {
  const StudentDash({super.key});

  @override
  State<StudentDash> createState() => _StudentDashState();
}

class _StudentDashState extends State<StudentDash> with WidgetsBindingObserver {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();
  final TtsService ttsService = TtsService();
  final AudioRecorder _audioRecorder = AudioRecorder();

  Map<String, dynamic>? result;
  bool searchedNicobarese = false;
  bool isLoading = false;
  
  // AI Assistant State
  bool _isRecording = false;
  bool _showAiOverlay = false;
  String _aiText = ""; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Preload dictionaries
    dictionaryService.loadDictionary(DictionaryType.words);
    dictionaryService.loadDictionary(DictionaryType.phrases);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    dictionaryService.unload(DictionaryType.words);
    _audioRecorder.dispose();
    super.dispose();
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      result = null;
      searchedNicobarese = false;
    });
  }

  Future<void> performSearch() async {
    FocusScope.of(context).unfocus();
    if (searchController.text.isEmpty) return;

    setState(() => isLoading = true);

    // 1. Direct Search
    var searchResult = await dictionaryService.searchEverywhere(
      searchController.text,
    );
    
    // 2. NLP Translation Fallback
    if (searchResult == null) {
        searchResult = await dictionaryService.translateSentence(searchController.text);
    }

    if (mounted) {
      setState(() {
        result = searchResult;
        
        if (searchResult != null) {
          if (searchResult!.containsKey('_searchedNicobarese')) {
              searchedNicobarese = searchResult!['_searchedNicobarese'];
          } else if (searchResult!.containsKey('_isGenerated')) {
             searchedNicobarese = false; 
          } else {
              final query = searchController.text.trim().toLowerCase();
              searchedNicobarese =
                  searchResult!['nicobarese'].toString().toLowerCase() == query;
          }
        } else {
          searchedNicobarese = false;
        }
        isLoading = false;
      });
    }
  }

  Future<String> _getModelPath() async {
     final Directory appDocDir = await getApplicationDocumentsDirectory();
     final String modelPath = '${appDocDir.path}/ggml-tiny.en.bin';
     
     if (!File(modelPath).existsSync()) {
       try {
         final ByteData data = await DefaultAssetBundle.of(context).load('assets/models/ggml-tiny.en.bin');
         final List<int> bytes = data.buffer.asUint8List();
         await File(modelPath).writeAsBytes(bytes);
       } catch (e) {
         print("Error copying model: $e");
       }
     }
     return modelPath;
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/temp_recording.wav';
        
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000), path: filePath);
        
        setState(() {
          _isRecording = true;
          _showAiOverlay = true; 
          _aiText = "Listening...";
        });
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to start recording: $e")));
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _aiText = "Thinking..."; 
      });

      if (path != null) {
        final modelPath = await _getModelPath();
        final text = await WhisperService().transcribe(modelPath, path);
        
        if (text.startsWith("Error")) {
           setState(() => _aiText = "Oops! I didn't catch that.");
        } else {
           final cleanText = text.replaceAll("[BLANK_AUDIO]", "").trim();
           setState(() {
               _aiText = cleanText.isEmpty ? "I heard silence..." : cleanText;
               searchController.text = cleanText; 
           });
           
           if (cleanText.isNotEmpty) {
               await Future.delayed(const Duration(seconds: 2));
               if (mounted) {
                   setState(() => _showAiOverlay = false);
                   performSearch();
               }
               return; 
           }
        }
      }
    } catch (e) {
       setState(() => _aiText = "Error: $e");
       debugPrint("Recording Error: $e");
    }
  }
  
  void _onMicTap() {
      if (_isRecording) {
          _stopRecording();
      } else {
          _startRecording();
      }
  }

  final List<Map<String, dynamic>> learningTiles = [
    {"word": "Numbers", "emoji": "123", "colors": [Color(0xFF6A11CB), Color(0xFF2575FC)], "navigateTo": NumberPage(), "icon": Icons.format_list_numbered_rounded},
    {"word": "Nature", "emoji": "🌱", "colors": [Color(0xFF11998E), Color(0xFF38EF7D)], "navigateTo": NaturePage(), "icon": Icons.eco_rounded},
    {"word": "Feelings", "emoji": "🎭", "colors": [Color(0xFFFF512F), Color(0xFFDD2476)], "navigateTo": FeelingsPage(), "icon": Icons.emoji_emotions_rounded},
    {"word": "Body Parts", "emoji": "🦴", "colors": [Color(0xFF8E2DE2), Color(0xFF4A00E0)], "navigateTo": BodyPartsScreen(), "icon": Icons.accessibility_new_rounded},
    {"word": "Games", "emoji": "🎲", "colors": [Color(0xFFF09819), Color(0xFFEDDE5D)], "navigateTo": const GamesHubScreen(), "icon": Icons.sports_esports_rounded},
    {"word": "Animals", "emoji": "🦁", "colors": [Color(0xFFFF8008), Color(0xFFFFC837)], "navigateTo": const AnimalsPage(), "icon": Icons.pets_rounded},
    {"word": "Magic Words", "emoji": "🔮", "colors": [Color(0xFFCC2B5E), Color(0xFF753A88)], "navigateTo": const MagicWordsPage(), "icon": Icons.auto_fix_high_rounded},
    {"word": "Family", "emoji": "👨‍👩‍👧", "colors": [Color(0xFF2193B0), Color(0xFF6DD5ED)], "navigateTo": const FamilyPage(), "icon": Icons.family_restroom_rounded},
    {"word": "Community", "emoji": "🌍", "colors": [Color(0xFF302B63), Color(0xFF24243E)], "navigateTo": const CommunityScreen(), "isSecret": true, "icon": Icons.public_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Background(
            colors: const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], // Premium Dark Theme
            padding: EdgeInsets.zero,
            child: SafeArea(
              child: Column(
                children: [
                   _buildHeroHeader(context),
                   const SizedBox(height: 10),
                   if (isLoading)
                     const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
                   else if (searchController.text.isNotEmpty)
                     Expanded(child: _buildSearchResults())
                   else
                     Expanded(child: _buildDashboardContent()),
                ],
              ),
            ),
          ),
          
          if (_showAiOverlay)
            AiAssistantOverlay(
                isListening: _isRecording,
                currentText: _aiText,
                onMicPressed: _onMicTap,
                onClose: () => setState(() => _showAiOverlay = false),
            )
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
      return Container(
         padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
         decoration: BoxDecoration(
           gradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
           borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
           border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
         ),
         child: Column(
           children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SpeechMate", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5)),
                      Text("Learn. Preserve. Connect.", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 2)),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.2), shape: BoxShape.circle),
                    child: IconButton(
                        icon: const Icon(Icons.mic_none_outlined, color: Colors.cyanAccent),
                        onPressed: _onMicTap, 
                    ),
                  )
                ],
              ),
              const SizedBox(height: 25),
              Search(
                 controller: searchController,
                 onSearch: performSearch,
                 onClear: clearSearch,
                 onMicTap: _onMicTap,
              ),
           ],
         ),
      );
  }

  Widget _buildSearchResults() {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: TranslationCard(
          nicobarese: result != null ? result!['nicobarese'] : "No match found",
          english: result != null ? (result!['english'] ?? result!['text'] ?? "") : "",
          isError: result == null,
          searchedNicobarese: searchedNicobarese,
          showSpeaker: result != null, 
          onSpeak: () {
              if (result == null) return;
              if (searchedNicobarese) {
                  ttsService.speakEnglish(result!['english'] ?? result!['text'] ?? "");
              } else {
                  ttsService.speakNicobarese(result!['nicobarese']);
              }
          },
        ),
      );
  }

  Widget _buildDashboardContent() {
      return SingleChildScrollView(
         physics: const BouncingScrollPhysics(),
         padding: const EdgeInsets.all(20),
         child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                 const Text("YOUR PROGRESS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 const SizedBox(height: 10),
                 const GamificationHeader(),
                 const SizedBox(height: 30),
                 const Text("EXPLORE MODULES", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 const SizedBox(height: 15),
                 GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: learningTiles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                        return _buildPremiumTile(learningTiles[index]);
                    },
                 ),
                 const SizedBox(height: 100),
             ],
         ),
      );
  }

  Widget _buildPremiumTile(Map<String, dynamic> tile) {
      return GestureDetector(
          onTap: () {
              if (tile['isSecret'] == true) {
                  _showSecretAccessDialog(context, tile['navigateTo']);
              } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => tile['navigateTo']));
              }
          },
          child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tile['colors'], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                      BoxShadow(color: (tile['colors'][0] as Color).withOpacity(0.4), blurRadius: 10, offset: const Offset(0,4))
                  ]
              ),
              child: Stack(
                  children: [
                      Positioned(right: -10, bottom: -10, child: Icon(tile['icon'], size: 80, color: Colors.white.withOpacity(0.2))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                      child: Icon(tile['icon'], color: Colors.white, size: 20),
                                  ),
                                  Text(tile['word'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                          ),
                      )
                  ],
              ),
          ),
      );
  }

  void _showSecretAccessDialog(BuildContext context, Widget targetScreen) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Senior Student Access 🔒"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Solve this to enter:\n\n12 + 15 = ?"),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Enter answer"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_controller.text.trim() == "27") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Incorrect. Access Denied 🚫")),
                );
              }
            },
            child: const Text("Enter"),
          ),
        ],
      ),
    );
  }
}
