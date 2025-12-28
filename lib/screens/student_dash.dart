  // ... imports
  import '../widgets/ai_assistant_overlay.dart'; // Add this import

  // ... inside _StudentDashState
  bool _showAiOverlay = false;
  String _aiText = ""; 

  // ... update _startRecording to show overlay
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/temp_recording.wav';
        
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000), path: filePath);
        
        setState(() {
          _isRecording = true;
          _showAiOverlay = true; // SHOW OVERLAY
          _aiText = "Listening...";
        });
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  // ... update _stopRecording
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _aiText = "Thinking..."; // Update text
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
               searchController.text = cleanText; // Auto-fill search
           });
           
           if (cleanText.isNotEmpty) {
               // Wait a moment so user reads text, then close and search
               await Future.delayed(const Duration(seconds: 2));
               setState(() => _showAiOverlay = false);
               performSearch();
               return; 
           }
        }
      }
    } catch (e) {
       setState(() => _aiText = "Error: $e");
    }
  }

  // ... Update Learning Tiles with better visuals
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
            ),
        ],
      ),
    );
  }

  // Refactored Helper Methods
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
                        onPressed: _onMicTap, // Quick AI Access
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
          onSpeakerTap: () {
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
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final tile = learningTiles[index];
                      return _buildPremiumTile(tile);
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
              if (tile.containsKey('isSecret') && tile['isSecret'] == true) {
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
                      ),
                  ],
              ),
          ),
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    dictionaryService.unload(DictionaryType.words);
    super.dispose();
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
              if (_controller.text == "27") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
              } else {
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
