import 'package:flutter/material.dart';
import '../../widgets/glass_container.dart';

class VoiceArchiveScreen extends StatefulWidget {
  const VoiceArchiveScreen({super.key});

  @override
  State<VoiceArchiveScreen> createState() => _VoiceArchiveScreenState();
}

class _VoiceArchiveScreenState extends State<VoiceArchiveScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isRecording = false;

  final List<Map<String, String>> contributions = [
    {"word": "Ka-he (Hello)", "contributor": "Elder John", "duration": "2s"},
    {"word": "In-yö (Water)", "contributor": "Mrs. Anita", "duration": "1.5s"},
    {"word": "Lö-ngö (Sky)", "contributor": "Chief Paul", "duration": "3s"},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 1));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      isRecording = !isRecording;
    });
    if (isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎙️ Recording started... (Mock)")));
    } else {
      // Finish Logic
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Recording saved to Archive!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Voice Archive 🎙️"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  opacity: 0.1,
                  child: Column(
                    children: [
                      const Text(
                        "Preserve The Sound",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Help us build the largest digital library of Nicobarese pronunciations.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Recording Button
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecording ? Colors.redAccent : Colors.cyanAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (isRecording ? Colors.red : Colors.cyan).withOpacity(0.5),
                            blurRadius: isRecording ? 20 + (_controller.value * 10) : 20,
                            spreadRadius: isRecording ? 5 + (_controller.value * 5) : 1,
                          )
                        ],
                      ),
                      child: Icon(
                        isRecording ? Icons.stop : Icons.mic,
                        size: 50,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              Text(
                isRecording ? "Recording..." : "Tap to Contribute",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 40),
              // Recent Contributions
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 25, left: 20, right: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Contributions",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          itemCount: contributions.length,
                          itemBuilder: (context, index) {
                            final item = contributions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.indigo.shade100,
                                    child: const Icon(Icons.play_arrow,
                                        color: Colors.indigo),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['word']!,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        Text("${item['contributor']} • ${item['duration']}",
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.verified,
                                      color: Colors.blueAccent, size: 20),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
