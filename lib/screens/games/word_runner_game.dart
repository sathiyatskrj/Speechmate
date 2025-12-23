import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/dictionary_service.dart';

class WordRunnerGame extends StatefulWidget {
  const WordRunnerGame({super.key});

  @override
  State<WordRunnerGame> createState() => _WordRunnerGameState();
}

enum GameState { menu, playing, gameOver, victory }
enum ItemType { obstacle, word, surprise }

// --- DATA CLASSES ---

class GameItem {
  double x;
  double y;
  double width;
  double height;
  ItemType type;
  String? value;
  Color color;
  bool collected;
  double rotation; // For visual flair

  GameItem({
    required this.x,
    required this.y,
    required this.type,
    this.width = 60,
    this.height = 60,
    this.value,
    this.color = Colors.red,
    this.collected = false,
    this.rotation = 0,
  });
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life; // 1.0 to 0.0
  Color color;
  double size;

  Particle({
    required this.x, 
    required this.y, 
    required this.vx, 
    required this.vy, 
    required this.color,
    this.life = 1.0,
    this.size = 5.0,
  });
}

// --- MAIN GAME WIDGET ---

class _WordRunnerGameState extends State<WordRunnerGame> with TickerProviderStateMixin {
  // Game Config
  static const double gravity = 0.6;
  static const double jumpForce = -16.0;
  static const double groundHeight = 100.0;
  
  // Services & Controllers
  final DictionaryService _dictionaryService = DictionaryService();
  late AnimationController _gameTicker; // High performance game loop
  
  // Game State
  GameState _gameState = GameState.menu;
  int _score = 0;
  int _level = 1;
  int _combo = 0; // Combo counter
  double _screenShake = 0.0; // Screen shake magnitude
  
  // Data
  List<String> _targetWords = [];
  List<String> _foundWords = [];
  final List<GameItem> _items = [];
  final List<Particle> _particles = [];
  
  // Player
  double _playerY = 0;
  double _playerVy = 0;
  bool _isGrounded = true;
  final double _playerX = 80;
  bool _isGoldMode = false;
  
  // World
  double _scrollSpeed = 6.0;
  double _distance = 0;
  double _time = 0; // For sine waves
  
  // Visuals
  final Random _rnd = Random();
  Color _skyTop = const Color(0xFF1a2a6c);
  Color _skyMid = const Color(0xFFb21f1f);
  Color _skyBot = const Color(0xFFfdbb2d);

  @override
  void initState() {
    super.initState();
    _loadDictionary();
    
    // 60 FPS Ticker
    _gameTicker = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _gameTicker.addListener(_gameLoop);
    _gameTicker.repeat();
  }

  Future<void> _loadDictionary() async {
    await _dictionaryService.loadDictionary(DictionaryType.words);
    _setupGame();
  }

  void _setupGame() {
    final allWords = _dictionaryService.getDictionary(DictionaryType.words);
    if (allWords.isEmpty) {
      _targetWords = ["CODE", "DEUS", "HACK", "WIN", "FAST", "EPIC", "COOL", "JAVA", "DART", "WEB"];
    } else {
      final shuffled = List<Map<String, dynamic>>.from(allWords)..shuffle();
      _targetWords = shuffled.take(10).map((e) => e['english'].toString().toUpperCase()).toList();
    }
    
    _resetState();
  }

  void _resetState() {
    if (!mounted) return;
    setState(() {
      _score = 0;
      _level = 1;
      _combo = 0;
      _foundWords.clear();
      _items.clear();
      _particles.clear();
      
      _playerY = 0;
      _playerVy = 0;
      _isGrounded = true;
      _distance = 0;
      _scrollSpeed = 7.0;
      
      _skyTop = const Color(0xFF1a2a6c);
      _skyMid = const Color(0xFFb21f1f);
      _skyBot = const Color(0xFFfdbb2d);
    });
  }

  void _startGame() {
    setState(() => _gameState = GameState.playing);
  }

  // --- GAME LOOP ---
  void _gameLoop() {
    if (_gameState != GameState.playing) return;
    
    setState(() {
      _time += 0.05;
      _distance += _scrollSpeed;
      
      // 1. Difficulty Ramp
      double speedMultiplier = 1.0 + (_level * 0.1) + (_combo * 0.05);
      double currentSpeed = _scrollSpeed * speedMultiplier;
      if (_isGoldMode) currentSpeed += 3.0;

      // 2. Physics
      _playerVy += gravity;
      _playerY += _playerVy;
      
      // Ground Collision
      if (_playerY >= 0) {
        _playerY = 0;
        _playerVy = 0;
        _isGrounded = true;
      }

      // 3. Spawning
      _handleSpawning();

      // 4. Update Items
      for (int i = _items.length - 1; i >= 0; i--) {
        GameItem item = _items[i];
        item.x -= currentSpeed;
        item.rotation += 0.05; // Spin effect
        
        // Floating effect for words
        if (item.type == ItemType.word) {
          item.y += sin(_time + item.x * 0.01) * 0.5;
        }

        // Collision
        if (!item.collected && _checkCollision(item)) {
          _handleCollision(item);
        }

        // Cleanup
        if (item.x < -200) _items.removeAt(i);
      }
      
      // 5. Particles
      for (int i = _particles.length - 1; i >= 0; i--) {
        Particle p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.2; // Gravity for particles
        p.life -= 0.02;
        if (p.life <= 0) _particles.removeAt(i);
      }
      
      // 6. Screen Shake Decay
      if (_screenShake > 0) _screenShake = max(0, _screenShake - 1);
      
      // 7. Win Check
      if (_foundWords.length >= 10 && _gameState != GameState.victory) {
        _gameState = GameState.victory;
        _createExplosion(_playerX, _playerY - 100, Colors.amber);
      }
    });
  }

  bool _checkCollision(GameItem item) {
    double pCenterX = _playerX + 25;
    double pCenterY = _playerY + 25; // Relative to ground, same as logic
    
    double iCenterX = item.x + item.width / 2;
    double iCenterY = item.y + item.height / 2; 

    double dx = pCenterX - iCenterX;
    double dy = pCenterY - iCenterY;
    double dist = sqrt(dx*dx + dy*dy);
    
    return dist < (30 + item.width / 3); // Hitbox radius
  }

  void _handleCollision(GameItem item) {
    item.collected = true;
    
    if (item.type == ItemType.obstacle) {
      if (_isGoldMode) {
        _score += 500;
        _createExplosion(item.x, item.y, Colors.red);
        _screenShake = 5.0;
      } else {
        _gameState = GameState.gameOver;
        _screenShake = 20.0;
        _createExplosion(_playerX, _playerY, Colors.red);
      }
    } 
    else if (item.type == ItemType.word) {
      String target = _targetWords[_foundWords.length];
      
      if (item.value == target) {
        // CORRECT
        _foundWords.add(item.value!);
        _combo++;
        int bonus = 100 * (1 + _combo);
        _score += bonus;
        _level++;
        _createExplosion(item.x, item.y, Colors.greenAccent);
      } 
      else if (_targetWords.contains(item.value) && !_foundWords.contains(item.value)) {
        // GOOD BUT OUT OF ORDER
        _foundWords.add(item.value!);
        _score += 100;
        _combo = 0; // Break combo
        _createExplosion(item.x, item.y, Colors.cyan);
      } 
      else {
        // WRONG
        _score = max(0, _score - 50);
        _combo = 0;
        _screenShake = 5.0;
        _createExplosion(item.x, item.y, Colors.grey);
      }
    } 
    else if (item.type == ItemType.surprise) {
      _activateGoldMode();
      _createExplosion(item.x, item.y, Colors.yellow);
    }
  }

  void _createExplosion(double x, double y, Color color) {
    for (int i = 0; i < 20; i++) {
      double angle = _rnd.nextDouble() * 2 * pi;
      double speed = _rnd.nextDouble() * 10 + 2;
      _particles.add(Particle(
        x: x, y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color.withOpacity(0.8),
        size: _rnd.nextDouble() * 8 + 2
      ));
    }
  }

  void _handleSpawning() {
    if (_rnd.nextInt(100) < 3) { // 3% chance per frame
      double roll = _rnd.nextDouble();
      double spawnX = MediaQuery.of(context).size.width + 100;
      
      if (roll < 0.4) {
        // Obstacle
        _items.add(GameItem(
          x: spawnX,
          y: 0, // Ground
          type: ItemType.obstacle,
          width: 50, height: 50
        ));
      } else if (roll < 0.8) {
        // Word
        String word;
        List<String> needed = _targetWords.where((w) => !_foundWords.contains(w)).toList();
        if (needed.isNotEmpty && _rnd.nextDouble() < 0.6) {
           word = needed.first; // High chance for NEXT needed word
        } else if (needed.isNotEmpty) {
           word = needed[_rnd.nextInt(needed.length)];
        } else {
           word = "WIN";
        }
        
        _items.add(GameItem(
          x: spawnX,
          y: 60.0 + _rnd.nextDouble() * 150, // Air
          type: ItemType.word,
          value: word,
          width: 100, height: 40,
          color: Colors.blue
        ));
      } else {
        // Surprise
        _items.add(GameItem(
          x: spawnX,
          y: 200,
          type: ItemType.surprise,
          width: 40, height: 40
        ));
      }
    }
  }

  void _activateGoldMode() {
    setState(() {
      _isGoldMode = true;
      _skyTop = Colors.purple;
      _skyMid = Colors.orange;
      _skyBot = Colors.yellow;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isGoldMode = false;
          _skyTop = const Color(0xFF1a2a6c);
          _skyMid = const Color(0xFFb21f1f);
          _skyBot = const Color(0xFFfdbb2d);
        });
      }
    });
  }

  void _jump() {
    if (_isGrounded) {
      _playerVy = jumpForce;
      _isGrounded = false;
      
      // Jump Particles
      for(int i=0; i<5; i++) {
        _particles.add(Particle(
          x: _playerX + 25, y: 5, 
          vx: (_rnd.nextDouble() - 0.5) * 5, 
          vy: 0, 
          color: Colors.white.withOpacity(0.5)
        ));
      }
    }
  }

  @override
  void dispose() {
    _gameTicker.dispose();
    super.dispose();
  }

  // --- RENDERING ---

  @override
  Widget build(BuildContext context) {
    // Screen Shake Transform
    double shakeX = (_rnd.nextDouble() - 0.5) * _screenShake;
    double shakeY = (_rnd.nextDouble() - 0.5) * _screenShake;

    return Transform.translate(
      offset: Offset(shakeX, shakeY),
      child: Scaffold(
        body: GestureDetector(
          onTapDown: (_) => _jump(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_skyTop, _skyMid, _skyBot],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            ),
            child: Stack(
              children: [
                // 1. Parallax Layers
                _buildParallaxLayer(speed: 0.2, color: Colors.white.withOpacity(0.2), icon: Icons.cloud, size: 100, y: 100),
                _buildParallaxLayer(speed: 0.5, color: Colors.white.withOpacity(0.1), icon: Icons.cloud, size: 60, y: 200),
                _buildParallaxLayer(speed: 0.8, color: Colors.black12, icon: Icons.landscape, size: 200, y: MediaQuery.of(context).size.height - 150),
                
                // 2. Game View (Custom Painter for performance with particles)
                Positioned.fill(
                  child: CustomPaint(
                    painter: GamePainter(
                      playerX: _playerX,
                      playerY: _playerY,
                      items: _items,
                      particles: _particles,
                      groundHeight: groundHeight,
                      isGoldMode: _isGoldMode,
                    ),
                  ),
                ),

                // 3. UI Layer
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // HUD Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHUD("SCORE", "$_score", Colors.amber),
                            if (_combo > 1) 
                              _buildHUD("COMBO", "${_combo}x", Colors.redAccent),
                            _buildHUD("GOAL", "${_foundWords.length}/${_targetWords.length}", Colors.cyan),
                          ],
                        ),
                        // Target Bar
                        const SizedBox(height: 20),
                        if (_gameState == GameState.playing)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24)
                          ),
                          child: Text(
                            _foundWords.length < _targetWords.length 
                             ? "FIND: ${_targetWords[_foundWords.length]}" 
                             : "RUSH TO FINISH!",
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 4. Overlays
                if (_gameState == GameState.menu) _buildMenu(),
                if (_gameState == GameState.gameOver) _buildGameOver(),
                if (_gameState == GameState.victory) _buildVictory(),
                
                // Back Button
                if (_gameState != GameState.playing)
                  Positioned(top: 40, left: 10, child: BackButton(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildParallaxLayer({required double speed, required Color color, required IconData icon, required double size, required double y}) {
    double pos = (_distance * speed) % (MediaQuery.of(context).size.width + size);
    return Positioned(
      left: -pos,
      top: y,
      child: Row(
        children: [
          Icon(icon, size: size, color: color),
          SizedBox(width: MediaQuery.of(context).size.width),
          Icon(icon, size: size, color: color),
        ],
      ),
    );
  }

  Widget _buildHUD(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)])),
      ],
    );
  }

  Widget _buildMenu() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("WORD\nRUNNER", textAlign: TextAlign.center, style: TextStyle(fontSize: 60, height: 0.9, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.purple, offset: Offset(4,4))])),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
            child: const Text("START RUN", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("CRASHED!", style: TextStyle(color: Colors.red, fontSize: 40, fontWeight: FontWeight.bold)),
            Text("Score: $_score", style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _setupGame, child: const Text("RETRY"))
          ],
        ),
      ),
    );
  }
  
  Widget _buildVictory() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("LEGEND!", style: TextStyle(color: Colors.amber, fontSize: 40, fontWeight: FontWeight.bold)),
            const Text("All Words Found", style: TextStyle(color: Colors.white70)),
            Text("Final Score: $_score", style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _setupGame, child: const Text("PLAY AGAIN"))
          ],
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER (Visual Engine) ---

class GamePainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final List<GameItem> items;
  final List<Particle> particles;
  final double groundHeight;
  final bool isGoldMode;

  GamePainter({
    required this.playerX, 
    required this.playerY, 
    required this.items, 
    required this.particles,
    required this.groundHeight,
    required this.isGoldMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Player
    final Paint playerPaint = Paint()
      ..color = isGoldMode ? Colors.yellow : Colors.white
      ..style = PaintingStyle.fill
      ..shader = isGoldMode ? ui.Gradient.linear(
          Offset(playerX, size.height - groundHeight - playerY), 
          Offset(playerX, size.height - groundHeight - playerY + 50), 
          [Colors.yellow, Colors.orange]) : null;

    // Draw Player shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(playerX + 25, size.height - groundHeight + 10), width: 40, height: 10),
      Paint()..color = Colors.black26
    );

    // Draw Player Body (Simple rounded rect for modern look)
    double drawY = size.height - groundHeight - playerY - 50;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(playerX, drawY, 50, 50), const Radius.circular(15)), 
      playerPaint
    );
    // Player Eye
    canvas.drawCircle(Offset(playerX + 35, drawY + 15), 5, Paint()..color = Colors.black);

    // 2. Draw Items
    for (var item in items) {
      double itemY = size.height - groundHeight - item.y - item.height;
      
      // Save canvas for rotations
      canvas.save();
      canvas.translate(item.x + item.width / 2, itemY + item.height / 2);
      canvas.rotate(item.rotation);
      canvas.translate(-(item.x + item.width / 2), -(itemY + item.height / 2));
      
      if (item.type == ItemType.obstacle) {
        // Draw Spikes
        final Path path = Path();
        path.moveTo(item.x, itemY + item.height);
        path.lineTo(item.x + item.width / 2, itemY);
        path.lineTo(item.x + item.width, itemY + item.height);
        path.close();
        canvas.drawPath(path, Paint()..color = Colors.redAccent);
      } else if (item.type == ItemType.word) {
        // Draw Word Bubble
        final Paint bubblePaint = Paint()
          ..color = item.color
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
          
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(item.x, itemY, item.width, item.height), const Radius.circular(10)), 
          bubblePaint
        );
        // Draw Text manually
        TextSpan span = TextSpan(style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), text: item.value);
        TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout(minWidth: item.width);
        tp.paint(canvas, Offset(item.x, itemY + 10)); // Approximate center
      } else {
        // Draw Star
        canvas.drawCircle(Offset(item.x + 20, itemY + 20), 15, Paint()..color = Colors.yellowAccent ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawCircle(Offset(item.x + 20, itemY + 20), 8, Paint()..color = Colors.white);
      }
      
      canvas.restore();
    }

    // 3. Draw Particles (High Performance)
    final Paint particlePaint = Paint();
    for (var p in particles) {
      double pY = size.height - groundHeight - p.y;
      particlePaint.color = p.color;
      if (p.life < 0.3) particlePaint.color = p.color.withOpacity(p.life * 3);
      
      canvas.drawCircle(Offset(p.x, pY), p.size, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Always repaint for games
}
