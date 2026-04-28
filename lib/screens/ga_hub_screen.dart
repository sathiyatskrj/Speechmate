import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/database_manager.dart';
import '../services/tts_service.dart';
import '../services/whisper_service.dart';
import '../widgets/background.dart';

/// Standalone Great Andamanese Hub
/// Contains: Dictionary, Text Translator, Voice (STT/TTS), OCR Scanner
class GAHubScreen extends StatefulWidget {
  const GAHubScreen({super.key});

  @override
  State<GAHubScreen> createState() => _GAHubScreenState();
}

class _GAHubScreenState extends State<GAHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TtsService _ttsService = TtsService();
  final WhisperService _whisperService = WhisperService();
  AudioRecorder? _audioRecorder;
  final TextEditingController _translateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Dictionary state
  List<Map<String, dynamic>> _allWords = [];
  List<Map<String, dynamic>> _filteredWords = [];
  List<Map<String, dynamic>> _phrases = [];
  bool _isLoading = true;
  String? _selectedPOS;
  final List<String> _posFilters = ['All', 'Noun', 'Verb', 'Adjective', 'Adverb', 'Deixis', 'Postposition'];

  // Translator state
  String _translatedText = '';
  bool _isTranslating = false;

  // Voice state
  bool _isRecording = false;
  bool _isProcessingVoice = false;
  String _voiceStatus = 'Tap mic to speak';
  String _voiceResult = '';
  String _voiceTranslation = '';

  // OCR state
  String _ocrText = '';
  String _ocrTranslation = '';
  bool _isProcessingOCR = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _ttsService.init();
    _loadData();
    _initWhisper();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ttsService.dispose();
    _audioRecorder?.dispose();
    _translateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initWhisper() async {
    await _whisperService.initialize();
  }

  Future<void> _loadData() async {
    final db = DatabaseManager.instance;
    final words = await db.getGADictionary();
    final ph = await db.getGAPhrases();
    if (mounted) {
      setState(() {
        _allWords = words;
        _filteredWords = words;
        _phrases = ph;
        _isLoading = false;
      });
    }
  }

  // ─── DICTIONARY LOGIC ───
  void _filterWords(String query) {
    setState(() {
      _filteredWords = _allWords.where((w) {
        final english = (w['english'] ?? '').toString().toLowerCase();
        final ga = (w['great_andamanese'] ?? '').toString().toLowerCase();
        final pos = (w['pos'] ?? '').toString();
        final matchesSearch = query.isEmpty ||
            english.contains(query.toLowerCase()) ||
            ga.contains(query.toLowerCase());
        final matchesPOS = _selectedPOS == null || pos == _selectedPOS;
        return matchesSearch && matchesPOS;
      }).toList();
    });
  }

  void _filterByPOS(String? pos) {
    setState(() {
      _selectedPOS = (pos == 'All') ? null : pos;
      _filterWords(_searchController.text);
    });
  }

  // ─── TRANSLATOR LOGIC ───
  Future<void> _translateText(String input) async {
    if (input.trim().isEmpty) return;
    setState(() { _isTranslating = true; _translatedText = ''; });

    final query = input.trim().toLowerCase();
    final db = DatabaseManager.instance;

    // Try exact match first
    final results = await db.searchGADictionary(query);
    if (results.isNotEmpty) {
      final match = results.first;
      setState(() {
        _translatedText = match['great_andamanese']?.toString() ?? 'No translation';
        _isTranslating = false;
      });
      return;
    }

    // Try word-by-word
    final tokens = input.trim().split(' ');
    List<String> translated = [];
    for (final token in tokens) {
      final clean = token.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
      final res = await db.searchGADictionary(clean);
      if (res.isNotEmpty) {
        translated.add(res.first['great_andamanese']?.toString() ?? token);
      } else {
        translated.add(token);
      }
    }

    setState(() {
      _translatedText = translated.join(' ');
      _isTranslating = false;
    });
  }

  // ─── VOICE (STT → TRANSLATE) ───
  Future<void> _toggleVoice() async {
    if (_isRecording) {
      // Stop
      setState(() { _isRecording = false; _isProcessingVoice = true; _voiceStatus = 'Processing...'; });
      try {
        final path = await _audioRecorder?.stop();
        if (path != null) {
          final text = await _whisperService.transcribe(path);
          if (text.trim().isNotEmpty) {
            setState(() { _voiceResult = text.trim(); });
            // Auto-translate
            final results = await DatabaseManager.instance.searchGADictionary(text.trim().toLowerCase());
            setState(() {
              _voiceTranslation = results.isNotEmpty
                  ? (results.first['great_andamanese']?.toString() ?? 'No match')
                  : 'No translation found';
              _isProcessingVoice = false;
              _voiceStatus = 'Tap mic to speak';
            });
          } else {
            setState(() { _isProcessingVoice = false; _voiceStatus = 'Could not hear. Try again.'; });
          }
        }
      } catch (e) {
        setState(() { _isProcessingVoice = false; _voiceStatus = 'Error: $e'; });
      }
    } else {
      // Start — always create a fresh recorder
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();
      if (await _audioRecorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/ga_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _audioRecorder!.start(
          const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1, sampleRate: 16000),
          path: path,
        );
        setState(() { _isRecording = true; _voiceStatus = 'Listening...'; _voiceResult = ''; _voiceTranslation = ''; });
      } else {
        setState(() { _voiceStatus = 'Mic permission denied'; });
      }
    }
  }

  // ─── OCR LOGIC ───
  Future<void> _scanImage() async {
    setState(() { _isProcessingOCR = true; _ocrText = ''; _ocrTranslation = ''; });
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) { setState(() => _isProcessingOCR = false); return; }

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      final rawText = result.text;
      if (rawText.isEmpty) {
        setState(() { _ocrText = 'No text detected'; _isProcessingOCR = false; });
        return;
      }

      setState(() { _ocrText = rawText; });

      // Translate each word
      final tokens = rawText.split(RegExp(r'\s+'));
      List<String> translated = [];
      for (final token in tokens) {
        final clean = token.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
        if (clean.isEmpty) continue;
        final res = await DatabaseManager.instance.searchGADictionary(clean);
        if (res.isNotEmpty) {
          translated.add(res.first['great_andamanese']?.toString() ?? token);
        } else {
          translated.add(token);
        }
      }

      setState(() {
        _ocrTranslation = translated.join(' ');
        _isProcessingOCR = false;
      });
    } catch (e) {
      setState(() { _ocrText = 'Error: $e'; _isProcessingOCR = false; });
    }
  }

  Future<void> _addToFlashcards(String english, String ga) async {
    await DatabaseManager.instance.saveGAFlashcard(english, ga);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ "$english" added to flashcards!'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🏝️ Great Andamanese'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(6)),
              child: const Text('BETA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4A148C),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.menu_book, size: 18), text: 'Dictionary (${_filteredWords.length})'),
            const Tab(icon: Icon(Icons.translate, size: 18), text: 'Translator'),
            const Tab(icon: Icon(Icons.mic, size: 18), text: 'Voice'),
            const Tab(icon: Icon(Icons.document_scanner, size: 18), text: 'OCR Scan'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A148C), Color(0xFF0D0D1A)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDictionaryTab(),
                  _buildTranslatorTab(),
                  _buildVoiceTab(),
                  _buildOCRTab(),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 1: DICTIONARY
  // ═══════════════════════════════════════════════
  Widget _buildDictionaryTab() {
    return Column(
      children: [
        _buildBetaBanner(),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterWords,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search English or Great Andamanese...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white54),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _posFilters.length,
            itemBuilder: (context, index) {
              final pos = _posFilters[index];
              final isSelected = (_selectedPOS == null && pos == 'All') || _selectedPOS == pos;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(pos, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => _filterByPOS(pos),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  selectedColor: Colors.deepPurpleAccent,
                  checkmarkColor: Colors.white,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredWords.isEmpty
              ? const Center(child: Text('No results found', style: TextStyle(color: Colors.white54, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filteredWords.length,
                  itemBuilder: (context, index) {
                    final word = _filteredWords[index];
                    final english = word['english']?.toString() ?? '';
                    final ga = word['great_andamanese']?.toString() ?? '';
                    final pos = word['pos']?.toString() ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(english, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(ga, style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                if (pos.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                                      child: Text(pos, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _ttsService.speakEnglish(english),
                            icon: const Icon(Icons.volume_up, color: Colors.white54),
                            tooltip: 'Speak',
                          ),
                          IconButton(
                            onPressed: () => _addToFlashcards(english, ga),
                            icon: const Icon(Icons.bookmark_add_outlined, color: Colors.amberAccent),
                            tooltip: 'Add to Flashcards',
                          ),
                        ],
                      ),
                    ).animate(delay: (30 * (index % 20)).ms).fadeIn(duration: 250.ms);
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 2: TEXT TRANSLATOR
  // ═══════════════════════════════════════════════
  Widget _buildTranslatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBetaBanner(),
          const SizedBox(height: 20),
          const Text('English → Great Andamanese', style: TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: TextField(
              controller: _translateController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type English text here...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _isTranslating ? null : () => _translateText(_translateController.text),
            icon: _isTranslating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.translate),
            label: Text(_isTranslating ? 'Translating...' : 'Translate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (_translatedText.isNotEmpty) ...[
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.deepPurple.withValues(alpha: 0.3), Colors.indigo.withValues(alpha: 0.2)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Translation:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_translatedText, style: const TextStyle(color: Colors.amberAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(onPressed: () => _ttsService.speakEnglish(_translateController.text), icon: const Icon(Icons.volume_up, color: Colors.white54)),
                      IconButton(onPressed: () => _addToFlashcards(_translateController.text, _translatedText), icon: const Icon(Icons.bookmark_add, color: Colors.amberAccent)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 3: VOICE (STT + TTS)
  // ═══════════════════════════════════════════════
  Widget _buildVoiceTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 40),
            const SizedBox(height: 10),
            const Text('Voice Translator', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('Speak in English and get Great Andamanese translation', style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 40),

            // Mic Button
            GestureDetector(
              onTap: _isProcessingVoice ? null : _toggleVoice,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isProcessingVoice ? Colors.grey.withValues(alpha: 0.3) : _isRecording ? Colors.pinkAccent : Colors.deepPurpleAccent,
                  boxShadow: [
                    if (_isRecording) BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.5), blurRadius: 25, spreadRadius: 8),
                  ],
                ),
                child: _isProcessingVoice
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _voiceStatus,
              style: TextStyle(color: _isRecording ? Colors.pinkAccent : Colors.white70, fontSize: 14, fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal),
            ),

            if (_voiceResult.isNotEmpty) ...[
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('You said:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(_voiceResult, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    if (_voiceTranslation.isNotEmpty) ...[
                      const Divider(color: Colors.white24, height: 30),
                      const Text('Great Andamanese:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(_voiceTranslation, style: const TextStyle(color: Colors.amberAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 4: OCR SCANNER
  // ═══════════════════════════════════════════════
  Widget _buildOCRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBetaBanner(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Icon(_isProcessingOCR ? Icons.hourglass_top : Icons.document_scanner_rounded, color: Colors.amberAccent, size: 60),
                const SizedBox(height: 15),
                const Text('Book / Text Scanner', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Take a photo of any English text to translate it to Great Andamanese', style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: _isProcessingOCR ? null : _scanImage,
                  icon: _isProcessingOCR
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt_rounded),
                  label: Text(_isProcessingOCR ? 'Scanning...' : 'Scan & Translate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),

          if (_ocrText.isNotEmpty) ...[
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detected Text:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_ocrText, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ],

          if (_ocrTranslation.isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.deepPurple.withValues(alpha: 0.3), Colors.indigo.withValues(alpha: 0.2)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Great Andamanese Translation:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_ocrTranslation, style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildBetaBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_rounded, color: Colors.orangeAccent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Beta: Great Andamanese data is under review. Nicobarese is the verified module.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
