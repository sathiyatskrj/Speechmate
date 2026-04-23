import 'package:flutter/material.dart';
import 'package:speechmate/services/local_llm_service.dart';

/// Contextual Sentence Builder Game
/// A gamification module where users drag and drop Nicobarese words 
/// to form sentences. The LLM validates the sentence structure.
class SentenceBuilderGame extends StatefulWidget {
  final List<String> availableWords;

  const SentenceBuilderGame({
    super.key,
    required this.availableWords,
  });

  @override
  State<SentenceBuilderGame> createState() => _SentenceBuilderGameState();
}

class _SentenceBuilderGameState extends State<SentenceBuilderGame> {
  final LocalLlmService _llmService = LocalLlmService();
  List<String> _wordBank = [];
  List<String> _sentenceZone = [];
  bool _isEvaluating = false;
  String _feedback = "";

  @override
  void initState() {
    super.initState();
    _wordBank = List.from(widget.availableWords);
    _llmService.initialize();
  }

  void _checkSentence() async {
    if (_sentenceZone.isEmpty) return;

    setState(() {
      _isEvaluating = true;
      _feedback = "Validating with AI Tutor...";
    });

    final sentence = _sentenceZone.join(" ");
    final result = await _llmService.evaluateSentence(sentence);

    setState(() {
      _isEvaluating = false;
      _feedback = result['feedback'] ?? "Could not evaluate.";
    });
  }

  void _reset() {
    setState(() {
      _wordBank = List.from(widget.availableWords);
      _sentenceZone.clear();
      _feedback = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sentence Builder Game"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Drag words here to build a Nicobarese sentence:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Sentence Construction Zone
            DragTarget<String>(
              onAcceptWithDetails: (details) {
                setState(() {
                  _sentenceZone.add(details.data);
                  _wordBank.remove(details.data);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  minHeight: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sentenceZone.map((word) {
                      return Chip(
                        label: Text(word),
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        onDeleted: () {
                          setState(() {
                            _sentenceZone.remove(word);
                            _wordBank.add(word);
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            
            // Word Bank
            const Text("Word Bank:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _wordBank.map((word) {
                return Draggable<String>(
                  data: word,
                  feedback: Material(
                    child: Chip(
                      label: Text(word),
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                  childWhenDragging: Chip(
                    label: Text(word),
                    backgroundColor: Colors.grey.withOpacity(0.5),
                  ),
                  child: Chip(
                    label: Text(word),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Feedback Area
            if (_feedback.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isEvaluating ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _feedback,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            // Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text("Reset"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isEvaluating ? null : _checkSentence,
                    child: _isEvaluating 
                      ? const CircularProgressIndicator() 
                      : const Text("Check Sentence"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
