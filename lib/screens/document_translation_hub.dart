import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf_sync;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class DocumentTranslationHub extends StatefulWidget {
  const DocumentTranslationHub({super.key});

  @override
  State<DocumentTranslationHub> createState() => _DocumentTranslationHubState();
}

class _DocumentTranslationHubState extends State<DocumentTranslationHub> {
  bool _isProcessing = false;
  String? _fileName;
  String _originalText = '';
  String _translatedText = '';
  double _progress = 0.0;
  
  // Stats
  int _totalWords = 0;
  int _translatedWords = 0;

  Map<String, String>? _dictCache;

  Future<void> _loadDictCache() async {
    if (_dictCache != null) return;
    final db = await DatabaseManager.instance.database;
    final rows = await db.query('words');
    _dictCache = {};
    for (var row in rows) {
      final eng = row['english']?.toString().toLowerCase();
      final nico = row['nicobarese']?.toString();
      if (eng != null && nico != null && eng.isNotEmpty) {
        _dictCache![eng] = nico;
      }
    }
  }

  Future<void> _pickAndProcessFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isProcessing = true;
          _fileName = result.files.single.name;
          _progress = 0.1;
          _originalText = '';
          _translatedText = '';
          _totalWords = 0;
          _translatedWords = 0;
        });

        // Load dictionary into memory to prevent SQLite thread hangs
        await _loadDictCache();
        setState(() => _progress = 0.2);

        final file = File(result.files.single.path!);
        String extractedText = '';

        if (_fileName!.toLowerCase().endsWith('.pdf')) {
          final pdf_sync.PdfDocument document = pdf_sync.PdfDocument(inputBytes: await file.readAsBytes());
          final pdf_sync.PdfTextExtractor extractor = pdf_sync.PdfTextExtractor(document);
          extractedText = extractor.extractText();
          document.dispose();
        } else if (_fileName!.toLowerCase().endsWith('.txt')) {
          extractedText = await file.readAsString();
        }

        if (extractedText.isEmpty) {
          _showError("No readable text found in document.");
          return;
        }

        setState(() {
          _originalText = extractedText;
          _progress = 0.3;
        });

        // Translate Text off main thread loop
        await _translateDocument(extractedText);
      }
    } catch (e) {
      _showError("Failed to parse document: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progress = 1.0;
        });
      }
    }
  }

  Future<void> _translateDocument(String text) async {
    if (_dictCache == null) return;
    
    List<String> lines = text.split('\n');
    StringBuffer translatedDoc = StringBuffer();
    
    int totalWordsToTranslate = text.split(RegExp(r'\s+')).length;
    int processedWords = 0;
    int localTranslated = 0;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.trim().isEmpty) {
        translatedDoc.writeln();
        continue;
      }

      RegExp wordExp = RegExp(r"[\w']+|[.,!?;]");
      Iterable<Match> matches = wordExp.allMatches(line);
      
      for (Match match in matches) {
        String word = match.group(0)!;
        
        if (RegExp(r'^[.,!?;]+$').hasMatch(word)) {
          translatedDoc.write('$word ');
          continue;
        }

        processedWords++;
        
        String lowerWord = word.toLowerCase();
        if (_dictCache!.containsKey(lowerWord)) {
          translatedDoc.write('${_dictCache![lowerWord]} ');
          localTranslated++;
        } else {
          translatedDoc.write('$word ');
        }
      }
      translatedDoc.writeln();

      // Yield to event loop to prevent UI hang every 50 lines
      if (i % 50 == 0) {
        setState(() {
          _progress = 0.3 + (0.7 * (processedWords / totalWordsToTranslate));
          _totalWords = processedWords;
          _translatedWords = localTranslated;
        });
        await Future.delayed(Duration.zero);
      }
    }

    setState(() {
      _translatedText = translatedDoc.toString();
      _totalWords = processedWords;
      _translatedWords = localTranslated;
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _exportAndShare() async {
    if (_translatedText.isEmpty) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/Translated_${_fileName ?? "Doc"}.txt');
      await file.writeAsString("=== ORIGINAL ===\n$_originalText\n\n=== NICOBARESE TRANSLATION ===\n$_translatedText");
      await Share.shareXFiles([XFile(file.path)], text: 'Translated Document');
    } catch (e) {
      _showError("Export failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.teacherTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Dark elegant background
        appBar: AppBar(
          title: const Text("Document Hub", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: 0.5, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_translatedText.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.ios_share_rounded, color: Colors.cyanAccent),
                onPressed: _exportAndShare,
                tooltip: "Export Translation",
              ).animate().fadeIn().scale(),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient Gradients
            Positioned(
              top: -150, right: -150,
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigoAccent.withValues(alpha: 0.15), filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100)),
              ),
            ),
            Positioned(
              bottom: -150, left: -150,
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withValues(alpha: 0.1), filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100)),
              ),
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Upload Section
                    if (_translatedText.isEmpty && !_isProcessing)
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: _pickAndProcessFile,
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 500),
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(color: Colors.indigoAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.document_scanner_rounded, size: 64, color: Colors.cyanAccent),
                                  ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                                  const SizedBox(height: 24),
                                  const Text("Select a PDF or TXT", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  const Text("Instantly parse and translate entire documents into Nicobarese natively, 100% offline.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5)),
                                  const SizedBox(height: 32),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                    ),
                                    child: const Text("Browse Files", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms),
                        ),
                      ),
                      
                    // Processing State
                    if (_isProcessing)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 120, height: 120,
                                child: CircularProgressIndicator(
                                  value: _progress,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.white10,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text("Parsing Neural Matrix...", style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)).animate().shimmer(duration: 1.seconds, curve: Curves.easeInOut),
                              const SizedBox(height: 10),
                              Text("${(_progress * 100).toInt()}% Complete", style: const TextStyle(color: Colors.white54, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),

                    // Results UI
                    if (_translatedText.isNotEmpty && !_isProcessing) ...[
                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(title: "Words", value: _totalWords.toString(), icon: Icons.text_snippet_rounded, color: Colors.blueAccent),
                            _StatItem(title: "Translated", value: _translatedWords.toString(), icon: Icons.translate_rounded, color: Colors.greenAccent),
                            _StatItem(title: "Coverage", value: "${((_translatedWords / (_totalWords == 0 ? 1 : _totalWords)) * 100).toInt()}%", icon: Icons.analytics_rounded, color: Colors.amberAccent),
                          ],
                        ),
                      ).animate().slideY(begin: -0.2).fadeIn(),
                      
                      // Split View
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              // Side by side for tablets/desktop
                              return Row(
                                children: [
                                  Expanded(child: _buildDocPanel("Original English", _originalText, Colors.blueGrey.shade700)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildDocPanel("Nicobarese Translation", _translatedText, Colors.indigoAccent.shade700, isAccent: true)),
                                ],
                              );
                            } else {
                              // Stacked for mobile
                              return DefaultTabController(
                                length: 2,
                                child: Column(
                                  children: [
                                    TabBar(
                                      indicatorColor: Colors.cyanAccent,
                                      labelColor: Colors.cyanAccent,
                                      unselectedLabelColor: Colors.white54,
                                      tabs: const [Tab(text: "Original"), Tab(text: "Nicobarese")],
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        children: [
                                          _buildDocPanel("English Text", _originalText, Colors.white10),
                                          _buildDocPanel("Nicobarese Result", _translatedText, Colors.indigoAccent.withValues(alpha: 0.2), isAccent: true),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocPanel(String title, String content, Color bgColor, {bool isAccent = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isAccent ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          if (isAccent) BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2)),
                child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isAccent ? Colors.cyanAccent : Colors.white70, letterSpacing: 1)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    content,
                    style: TextStyle(fontSize: 16, height: 1.8, color: isAccent ? Colors.white : Colors.white70, fontWeight: isAccent ? FontWeight.w500 : FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 0.5)),
      ],
    );
  }
}
