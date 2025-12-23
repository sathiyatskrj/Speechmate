import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/dictionary_service.dart';

class WordRunnerGame extends StatefulWidget {
  const WordRunnerGame({super.key});

  @override
  State<WordRunnerGame> createState() => _WordRunnerGameState();
}

enum GameState { menu, playing, gameOver, victory }
enum ItemType { obstacle, word, surprise }

class GameObject {
  double x;
  double y;
  double width;
  double height;
  ItemType type;
  String? value; // For words
  Color color;
  bool collected;

  GameObject({
    required this.x,
    required this.y,
    required this.type,
    this.width = 50,
    this.height = 50,
    this.value,
    this.color = Colors.red,
    this.collected = false,
  });
}

class _WordRunnerGameState extends State<WordRunnerGame> with TickerProviderStateMixin {
  // Game Configuration
  static const double gravity = 0.8;
  static const double jumpForce = -20.0;
  static const double groundHeight = 100.0;
  
  // Services
  final DictionaryService _dictionaryService = DictionaryService();
  
  // Game Loop
  Timer? _gameLoop;
  
  // Game State
  GameState _gameState = GameState.menu;
  int _score = 0;
  int _level = 1;
  final int _maxLevels = 10;
  List<String> _targetWords = [];
  List<String> _foundWords = [];
  
  // Player State
  double _playerY = 0;
  double _playerVelocityY = 0;
  bool _isGrounded = true;
  final double _playerX = 50; // Fixed horizontal position
  
  // World State
  double _scrollSpeed = 5.0;
  double _distanceTraveled = 0;
  final List<GameObject> _objects = [];
  
  // Visuals
  Color _skyColor = const Color(0xFF87CEEB);
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    // Only load words if not already loaded or reload if needed
    // Since DictionaryService manages cache, we can just call it
    await _dictionaryService.loadDictionary(DictionaryType.words);
    _setupGame();
  }

  void _setupGame() {
    final allWords = _dictionaryService.getDictionary(DictionaryType.words);
    if (allWords.isEmpty) {
      // Fallback if dictionary empty
      _targetWords = ["APPLE", "BANANA", "CAT", "DOG", "EGG", "FISH", "GOAT", "HAT", "ICE", "JUMP"];
    } else {
      // Pick 10 random words
      // Only picking English words for simplicity of display
      final shuffled = List<Map<String, dynamic>>.from(allWords)..shuffle();
      _targetWords = shuffled.take(10).map((e) => e['english'].toString().toUpperCase()).toList();
    }
    
    // Reset State
    _score = 0;
    _level = 1;
    _foundWords = [];
    _objects.clear();
    _playerY = 0;
    _playerVelocityY = 0;
    _scrollSpeed = 5.0;
    _distanceTraveled = 0;
    
    if (mounted) {
      setState(() {
        _gameState = GameState.menu;
      });
    }
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
    });
    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _update);
  }

  void _jump() {
    if (_gameState != GameState.playing) return;
    
    // Allow double jump? For now just single jump from ground
    if (_isGrounded) {
      setState(() {
        _playerVelocityY = jumpForce;
        _isGrounded = false;
      });
    }
  }

  void _update(Timer timer) {
    if (_gameState != GameState.playing) return;

    setState(() {
      // 1. Physics
      _playerVelocityY += gravity;
      _playerY += _playerVelocityY;

      // Ground Collision
      if (_playerY >= 0) { // Assuming 0 is ground level relative to bottom
        _playerY = 0;
        _playerVelocityY = 0;
        _isGrounded = true;
      }

      // 2. World Movement
      _scrollSpeed = 6.0 + (_level * 0.5); // Increase speed with level
      _distanceTraveled += _scrollSpeed;

      // 3. Spawning Objects
      _spawnObjects();

      // 4. Update Objects & Collision
      for (int i = _objects.length - 1; i >= 0; i--) {
        GameObject obj = _objects[i];
        obj.x -= _scrollSpeed;

        // Collision Check
        bool collision = !obj.collected && _checkCollision(
          // Player Rect
          Rect.fromLTWH(
             _playerX, 
             _playerY + 10, // Slight hitbox adjustment
             40, 
             40
          ),
          // Object Rect
          Rect.fromLTWH(
             obj.x, 
             obj.y, // relative to ground
             obj.width, 
             obj.height
          )
        );

        if (collision) {
          _handleCollision(obj);
        }

        // Remove off-screen
        if (obj.x < -100) {
          _objects.removeAt(i);
        }
      }

      // 5. Level & Win Condition
      if (_foundWords.length >= _maxLevels) {
        _winGame();
      }
    });
  }

  bool _checkCollision(Rect player, Rect obj) {
    return player.overlaps(obj);
  }

  void _handleCollision(GameObject obj) {
    if (obj.type == ItemType.obstacle) {
      // Game Over
      _gameOver();
    } else if (obj.type == ItemType.word) {
      if (_foundWords.length < _targetWords.length && obj.value == _targetWords[_foundWords.length]) {
        // Correct Word!
        obj.collected = true;
        _foundWords.add(obj.value!);
        _score += 100;
        _level++;
        _triggerSuprise(); // Visual feedback
      } else {
        // Simple penalty for wrong word
        if (_targetWords.contains(obj.value) && !_foundWords.contains(obj.value)) {
           obj.collected = true;
           _foundWords.add(obj.value!);
           _score += 100;
           _level = min(_maxLevels, _level + 1);
           
           if (_foundWords.length >= 10) _winGame();
        } else {
           if (!obj.collected) {
             _score = max(0, _score - 50);
             obj.collected = true;
           }
        }
      }
    } else if (obj.type == ItemType.surprise) {
      if (!obj.collected) {
        obj.collected = true;
        _triggerSuprise();
        _score += 500;
      }
    }
  }

  void _triggerSuprise() {
     setState(() {
        _skyColor = Colors.primaries[_random.nextInt(Colors.primaries.length)].shade200;
     });
     
     Future.delayed(const Duration(milliseconds: 500), () {
       if (mounted) setState(() => _skyColor = const Color(0xFF87CEEB));
     });
  }

  void _spawnObjects() {
    if (_random.nextInt(100) < 2) { 
       double typeRoll = _random.nextDouble();
       
       if (typeRoll < 0.4) {
         // Obstacle
         _objects.add(GameObject(
           x: MediaQuery.of(context).size.width,
           y: 0,
           type: ItemType.obstacle,
           width: 40,
           height: 40,
           color: Colors.red.shade900,
         ));
       } else if (typeRoll < 0.7) {
         // Word
         String wordToSpawn;
         final remaining = _targetWords.where((w) => !_foundWords.contains(w)).toList();
         
         if (remaining.isNotEmpty && _random.nextDouble() < 0.6) {
            wordToSpawn = remaining[_random.nextInt(remaining.length)];
         } else {
            wordToSpawn = _targetWords[_random.nextInt(_targetWords.length)];
         }

         _objects.add(GameObject(
           x: MediaQuery.of(context).size.width,
           y: 50.0 + _random.nextInt(150),
           type: ItemType.word,
           value: wordToSpawn,
           width: 100,
           height: 40,
           color: Colors.blueAccent,
         ));
       } else if (typeRoll < 0.75) {
         // Surprise
         _objects.add(GameObject(
           x: MediaQuery.of(context).size.width,
           y: 150,
           type: ItemType.surprise,
           width: 40,
           height: 40,
           color: Colors.purpleAccent,
         ));
       }
    }
  }

  void _gameOver() {
    _gameLoop?.cancel();
    setState(() {
      _gameState = GameState.gameOver;
    });
  }

  void _winGame() {
    _gameLoop?.cancel();
    setState(() {
      _gameState = GameState.victory;
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapUp: (_) => _jump(),
        onTapDown: (_) => _jump(),
        child: Container(
          color: _skyColor,
          child: Stack(
            children: [
              // Background
              Positioned(
                top: 50,
                right: (_distanceTraveled * 0.1) % (MediaQuery.of(context).size.width + 200) - 100,
                child: const Icon(Icons.cloud, size: 80, color: Colors.white54),
              ),
              Positioned(
                top: 100,
                right: ((_distanceTraveled * 0.05) + 200) % (MediaQuery.of(context).size.width + 200) - 100,
                child: const Icon(Icons.cloud, size: 60, color: Colors.white38),
              ),

              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: groundHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.brown,
                    border: Border(top: BorderSide(color: Colors.green.shade800, width: 10)),
                  ),
                  child: const Center(child: Text("TAP TO JUMP", style: TextStyle(color: Colors.white30))),
                ),
              ),

              // Objects
              ..._objects.map((obj) => Positioned(
                left: obj.x,
                bottom: groundHeight + obj.y,
                child: _buildObject(obj),
              )),

              // Player
              Positioned(
                left: _playerX,
                bottom: groundHeight + _playerY,
                child: Transform.rotate(
                   angle: _gameState == GameState.playing ? (_playerY / 100) * 0.5 : 0,
                   child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.directions_run,
                      size: 50,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                ),
              ),
              
              // HUD
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHudChip("Level", "$_level"),
                          _buildHudChip("Score", "$_score"),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15)),
                        child: Text(
                          "Objective: Find 10 Words (${_foundWords.length}/10)", 
                          style: const TextStyle(color: Colors.white)
                        ),
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: _foundWords.length / _maxLevels,
                        backgroundColor: Colors.white30,
                        color: Colors.greenAccent,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),

              // Overlays
              if (_gameState == GameState.menu) _buildMenuOverlay(),
              if (_gameState == GameState.gameOver) _buildGameOverOverlay(),
              if (_gameState == GameState.victory) _buildVictoryOverlay(),
              
              // Back Button
              if (_gameState != GameState.playing)
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObject(GameObject obj) {
    if (obj.type == ItemType.word) {
       bool isNeeded = _targetWords.contains(obj.value) && !_foundWords.contains(obj.value);
       Color cardColor = isNeeded ? Colors.orange : Colors.grey;
       
       return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(2,2), blurRadius: 4)],
          ),
          child: Text(
            obj.value ?? "",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
       );
    } else if (obj.type == ItemType.surprise) {
       return Container(
         width: obj.width,
         height: obj.height,
         decoration: const BoxDecoration(
           shape: BoxShape.circle,
           color: Colors.purple,
           boxShadow: [BoxShadow(color: Colors.purpleAccent, blurRadius: 10, spreadRadius: 2)],
         ),
         child: const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
       );
    } else {
       return Container(
         width: obj.width,
         height: obj.height,
         decoration: BoxDecoration(
           color: obj.color,
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: Colors.redAccent, width: 2),
         ),
         child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
       );
    }
  }

  Widget _buildHudChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_run_outlined, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            const Text("WORD RUNNER", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 20),
            const Text("1. Tap to Jump\n2. Collect target English words\n3. Avoid Red Obstacles", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text("START RUN"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, size: 60, color: Colors.red),
            const SizedBox(height: 10),
            const Text("GAME OVER", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 20),
            Text("Score: $_score", style: const TextStyle(fontSize: 24)),
            Text("Words: ${_foundWords.length}/10", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _foundWords.map((w) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Chip(label: Text(w)),
                )).toList(),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _setupGame,
                  child: const Text("RETRY"),
                ),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("EXIT"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 10),
            const Text("VICTORY!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 20),
            const Text("You completed all 10 levels!", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("Final Score: $_score", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
             const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _setupGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, 
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
              ),
              child: const Text("PLAY AGAIN", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
             const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("EXIT"),
            ),
          ],
        ),
      ),
    );
  }
}
