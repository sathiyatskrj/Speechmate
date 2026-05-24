import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceVaultScreen extends StatefulWidget {
  const VoiceVaultScreen({super.key});

  @override
  State<VoiceVaultScreen> createState() => _VoiceVaultScreenState();
}

class _VoiceVaultScreenState extends State<VoiceVaultScreen>
    with SingleTickerProviderStateMixin {
  AudioRecorder? _audioRecorder;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;

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

  // Vibrant color palette
  static const _mint = Color(0xFF00D4AA);
  static const _coral = Color(0xFFFF6B6B);
  static const _sky = Color(0xFF4ECDC4);
  static const _sunflower = Color(0xFFFFE66D);
  static const _lavender = Color(0xFFA78BFA);
  static const _peach = Color(0xFFFFB4A2);
  static const _bgLight = Color(0xFFF7F8FC);
  static const _cardWhite = Color(0xFFFFFFFF);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textMuted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();
      if (await _audioRecorder!.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/temp_vault_recording.wav';

        await _audioRecorder!.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordedPath = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mic error: $e"),
          backgroundColor: _coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder?.stop();
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
      _audioPlayer.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  void _submitRecording() {
    if (_recordedPath == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _mint, strokeWidth: 3),
              SizedBox(height: 16),
              Text("Submitting...", style: TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context);
      _saveContribution(
          "Recording #${_contributions.length + 1} - ${DateTime.now().toString().substring(0, 16)}");

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Thank You! 🏆",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: _textDark)),
          content: Text(
            "Your voice has been added to the Nicobarese AI Dataset. You are helping preserve the language!",
            style: GoogleFonts.inter(color: _textMuted, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _recordedPath = null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_mint, _sky]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text("Awesome!",
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildModeToggle()
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    _buildHeaderCard()
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    _isElderMode
                        ? _buildElderVerificationView()
                        : _buildRecordingView(),
                    if (!_isElderMode) ...[
                      const SizedBox(height: 24),
                      _buildContributionsList(),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _cardWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: _textDark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Voice Vault",
                    style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _textDark)),
                Text("Preserve heritage voices",
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _textMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_sunflower, _peach]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text("${_contributions.length * 10} XP",
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleTab("🎙️ Contribute", !_isElderMode, () {
            setState(() => _isElderMode = false);
          })),
          const SizedBox(width: 4),
          Expanded(child: _buildToggleTab("🛡️ Validate", _isElderMode, () {
            setState(() => _isElderMode = true);
          })),
        ],
      ),
    );
  }

  Widget _buildToggleTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [_mint, _sky])
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : _textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isElderMode
              ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
              : [_mint, _sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isElderMode ? _lavender : _mint).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _isElderMode ? Icons.verified_user_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isElderMode ? "Verify Contributions" : "Help Us Grow! 🌱",
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _isElderMode
                      ? "Listen to recordings and verify accuracy."
                      : "Record words to train our AI and preserve the language.",
                  style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView() {
    if (_recordedPath == null) {
      return Column(
        children: [
          const SizedBox(height: 20),
          // Big record button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isRecording
                    ? 1.0 + (_pulseController.value * 0.08)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isRecording
                            ? [_coral, const Color(0xFFFF8E53)]
                            : [_mint, _sky],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? _coral : _mint)
                              .withOpacity(0.35),
                          blurRadius: _isRecording ? 30 : 20,
                          spreadRadius: _isRecording ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.85, 0.85)),
          const SizedBox(height: 20),
          Text(
            _isRecording ? "Listening... Tap to Stop" : "Tap to Record",
            style: GoogleFonts.outfit(
                color: _textDark, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _isRecording
                ? "Speak the Nicobarese word clearly"
                : "Contribute your voice to the dataset",
            style: GoogleFonts.inter(color: _textMuted, fontSize: 13),
          ),
        ],
      );
    }

    // Review state
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF56AB2F), Color(0xFFA8E063)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text("Recording Captured!",
                  style: GoogleFonts.outfit(
                      color: _textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionCircle(
                    icon: _isPlaying
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    color: _sky,
                    onTap: _playRecording,
                  ),
                  const SizedBox(width: 24),
                  _buildActionCircle(
                    icon: Icons.delete_forever_rounded,
                    color: _coral,
                    onTap: () => setState(() => _recordedPath = null),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitRecording,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: Text("Submit to Dataset",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _mint,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 36),
      ),
    );
  }

  Widget _buildElderVerificationView() {
    if (_pendingReviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: _mint, size: 64),
            const SizedBox(height: 16),
            Text("All caught up!",
                style: GoogleFonts.outfit(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("No pending reviews right now.",
                style: GoogleFonts.inter(color: _textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_pendingReviews.length, (index) {
        final review = _pendingReviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _lavender.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.audiotrack_rounded,
                        color: _lavender, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review['title'],
                            style: GoogleFonts.outfit(
                                color: _textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text("Pending P2P Validation",
                            style: GoogleFonts.inter(
                                color: _textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF56AB2F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_rounded,
                            size: 12, color: Color(0xFF56AB2F)),
                        const SizedBox(width: 4),
                        Text("${review['upvotes']}",
                            style: GoogleFonts.outfit(
                                color: const Color(0xFF56AB2F),
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReviewButton(
                    icon: Icons.play_circle_fill_rounded,
                    label: "Play",
                    color: _sky,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text("Playing audio preview..."),
                        backgroundColor: _sky,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
                  ),
                  _buildReviewButton(
                    icon: Icons.thumb_down_alt_rounded,
                    label: "Reject",
                    color: _coral,
                    onTap: () {
                      setState(() => _pendingReviews[index]['downvotes']++);
                    },
                  ),
                  _buildReviewButton(
                    icon: Icons.thumb_up_alt_rounded,
                    label: "Approve",
                    color: const Color(0xFF56AB2F),
                    onTap: () {
                      setState(() {
                        _pendingReviews[index]['upvotes']++;
                        if (_pendingReviews[index]['upvotes'] >= 50) {
                          _pendingReviews.removeAt(index);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                const Text("Recording verified with 50+ votes!"),
                            backgroundColor: _mint,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.05);
      }),
    );
  }

  Widget _buildReviewButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildContributionsList() {
    if (_contributions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.record_voice_over_rounded,
                color: _peach, size: 40),
            const SizedBox(height: 12),
            Text("No contributions yet",
                style: GoogleFonts.outfit(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text("Record your first word to get started!",
                style: GoogleFonts.inter(color: _textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Contributions",
            style: GoogleFonts.outfit(
                color: _textDark, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...List.generate(
          _contributions.length > 5 ? 5 : _contributions.length,
          (index) {
            final i = _contributions.length - 1 - index;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _cardWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _mint.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: _mint, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_contributions[i],
                        style: GoogleFonts.inter(
                            color: _textDark, fontSize: 13)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _sunflower.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("+10 XP",
                        style: GoogleFonts.outfit(
                            color: const Color(0xFFD4A017),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (index * 60).ms);
          },
        ),
      ],
    );
  }
}
