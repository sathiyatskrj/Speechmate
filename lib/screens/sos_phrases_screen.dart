import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/tts_service.dart';

// ============================================================================
// EMERGENCY SOS PHRASES SCREEN
// Safety-critical — large text, high contrast, 4 languages, zero connectivity
// ============================================================================

class SOSPhrasesScreen extends StatefulWidget {
  const SOSPhrasesScreen({super.key});

  @override
  State<SOSPhrasesScreen> createState() => _SOSPhrasesScreenState();
}

class _SOSPhrasesScreenState extends State<SOSPhrasesScreen>
    with SingleTickerProviderStateMixin {
  final TtsService _tts = TtsService();
  late AnimationController _pulseController;
  String _selectedCategory = 'medical';

  static const _categories = {
    'medical': {'icon': '🏥', 'label': 'Medical', 'color': Color(0xFFFF4444)},
    'lost': {'icon': '🧭', 'label': 'Lost / Help', 'color': Color(0xFFFF8800)},
    'police': {'icon': '🚔', 'label': 'Authority', 'color': Color(0xFF4488FF)},
    'general': {'icon': '🆘', 'label': 'General', 'color': Color(0xFFFF6B6B)},
  };

  // Hardcoded — zero connectivity required, zero DB queries
  static const Map<String, List<Map<String, String>>> _phrases = {
    'medical': [
      {
        'en': 'I need a doctor',
        'ni': 'Chu-ö daktar chāhiye',
        'hi': 'मुझे डॉक्टर चाहिए',
        'ta': 'எனக்கு மருத்துவர் வேண்டும்',
      },
      {
        'en': 'It hurts here',
        'ni': 'Ngih-ö hārivlön',
        'hi': 'यहाँ दर्द हो रहा है',
        'ta': 'இங்கே வலிக்கிறது',
      },
      {
        'en': 'I am allergic',
        'ni': 'Chu-ö allergy hai',
        'hi': 'मुझे एलर्जी है',
        'ta': 'எனக்கு ஒவ்வாமை உள்ளது',
      },
      {
        'en': 'I need medicine',
        'ni': 'Chu-ö dawāi chāhiye',
        'hi': 'मुझे दवाई चाहिए',
        'ta': 'எனக்கு மருந்து வேண்டும்',
      },
      {
        'en': 'Call an ambulance',
        'ni': 'Ambulance bulāo',
        'hi': 'एम्बुलेंस बुलाओ',
        'ta': 'ஆம்புலன்ஸ் அழையுங்கள்',
      },
      {
        'en': 'I cannot breathe',
        'ni': 'Chu-ö sāns nahi le pā rahā',
        'hi': 'मैं साँस नहीं ले पा रहा',
        'ta': 'என்னால் மூச்சு விட முடியவில்லை',
      },
    ],
    'lost': [
      {
        'en': 'I am lost',
        'ni': 'Chu-ö tālöktū vāich',
        'hi': 'मैं खो गया हूँ',
        'ta': 'நான் வழி தவறிவிட்டேன்',
      },
      {
        'en': 'Where am I?',
        'ni': 'Chu-ö kahāng?',
        'hi': 'मैं कहाँ हूँ?',
        'ta': 'நான் எங்கே இருக்கிறேன்?',
      },
      {
        'en': 'Help me please',
        'ni': 'Hayöökën chu-ö',
        'hi': 'मेरी मदद करो',
        'ta': 'எனக்கு உதவி செய்யுங்கள்',
      },
      {
        'en': 'Where is the police station?',
        'ni': 'Police station kahāng?',
        'hi': 'पुलिस स्टेशन कहाँ है?',
        'ta': 'காவல் நிலையம் எங்கே?',
      },
      {
        'en': 'Where is the hospital?',
        'ni': 'Hospital kahāng?',
        'hi': 'अस्पताल कहाँ है?',
        'ta': 'மருத்துவமனை எங்கே?',
      },
      {
        'en': 'I need to go to the jetty',
        'ni': 'Chu-ö jetty umā-anh',
        'hi': 'मुझे जेट्टी जाना है',
        'ta': 'நான் படகுத்துறைக்கு செல்ல வேண்டும்',
      },
    ],
    'police': [
      {
        'en': 'Call the police',
        'ni': 'Police bulāo',
        'hi': 'पुलिस बुलाओ',
        'ta': 'போலீஸை அழையுங்கள்',
      },
      {
        'en': 'I need help from authority',
        'ni': 'Chu-ö authority hayöökën',
        'hi': 'मुझे अधिकारी की मदद चाहिए',
        'ta': 'எனக்கு அதிகாரியின் உதவி வேண்டும்',
      },
      {
        'en': 'Someone stole my belongings',
        'ni': 'Kēkeh chu-ö sāmān',
        'hi': 'किसी ने मेरा सामान चुराया',
        'ta': 'யாரோ என் பொருட்களை திருடிவிட்டார்கள்',
      },
      {
        'en': 'I am a tourist / visitor',
        'ni': 'Chu-ö tourist hai',
        'hi': 'मैं पर्यटक हूँ',
        'ta': 'நான் சுற்றுலா பயணி',
      },
      {
        'en': 'This is an emergency',
        'ni': 'Ngih emergency hai',
        'hi': 'यह आपातकालीन स्थिति है',
        'ta': 'இது அவசரநிலை',
      },
    ],
    'general': [
      {
        'en': 'I do not understand',
        'ni': 'Chu-ö akāk-el vāich',
        'hi': 'मुझे समझ नहीं आ रहा',
        'ta': 'எனக்கு புரியவில்லை',
      },
      {
        'en': 'Please speak slowly',
        'ni': 'Hārëmngēnre rō-ōvö',
        'hi': 'कृपया धीरे बोलो',
        'ta': 'தயவுசெய்து மெதுவாக பேசுங்கள்',
      },
      {
        'en': 'I need water',
        'ni': 'Chu-ö mak chāhiye',
        'hi': 'मुझे पानी चाहिए',
        'ta': 'எனக்கு தண்ணீர் வேண்டும்',
      },
      {
        'en': 'I need food',
        'ni': 'Chu-ö nyā-ān chāhiye',
        'hi': 'मुझे खाना चाहिए',
        'ta': 'எனக்கு உணவு வேண்டும்',
      },
      {
        'en': 'Thank you for helping',
        'ni': 'Dhanyavād hayöökën',
        'hi': 'मदद के लिए धन्यवाद',
        'ta': 'உதவிக்கு நன்றி',
      },
      {
        'en': 'My name is...',
        'ni': 'Chu-ö lēang...',
        'hi': 'मेरा नाम है...',
        'ta': 'என் பெயர்...',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tts.init();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _speakPhrase(String text, String lang) {
    HapticFeedback.heavyImpact();
    switch (lang) {
      case 'en':
        _tts.speakEnglish(text);
        break;
      case 'hi':
        _tts.speakRegional(text, 'hi-IN');
        break;
      case 'ta':
        _tts.speakRegional(text, 'ta-IN');
        break;
      case 'ni':
        _tts.speakNicobarese(text);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catData = _categories[_selectedCategory]!;
    final phrases = _phrases[_selectedCategory]!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0000),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Emergency SOS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Urgent gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0xFF4A0000), Color(0xFF1A0000), Color(0xFF0D0000)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Pulsing SOS Beacon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (ctx, _) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15 + 0.15 * _pulseController.value),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4 + 0.4 * _pulseController.value),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.2 * _pulseController.value),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emergency, color: Colors.red.shade300, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'TAP ANY PHRASE TO SPEAK IT',
                          style: TextStyle(
                            color: Colors.red.shade200,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category tabs
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _categories.entries.map((e) {
                      final isSelected = _selectedCategory == e.key;
                      final color = e.value['color'] as Color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedCategory = e.key);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(e.value['icon'] as String, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  e.value['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? color : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Phrase cards
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: phrases.length,
                    itemBuilder: (context, index) {
                      final phrase = phrases[index];
                      final color = catData['color'] as Color;
                      return _buildPhraseCard(phrase, color, index);
                    },
                  ),
                ),

                // Emergency number strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _emergencyNumber('🚑 102', 'Ambulance'),
                      _emergencyNumber('🚔 100', 'Police'),
                      _emergencyNumber('🆘 112', 'Emergency'),
                      _emergencyNumber('🔥 101', 'Fire'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseCard(Map<String, String> phrase, Color accentColor, int index) {
    return GestureDetector(
      onTap: () => _speakPhrase(phrase['en']!, 'en'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // English — largest, bold
            Text(
              phrase['en']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // Nicobarese — accent color
            _langRow('🏝️', 'Nicobarese', phrase['ni']!, accentColor, 'ni'),
            const SizedBox(height: 6),

            // Hindi
            _langRow('🇮🇳', 'Hindi', phrase['hi']!, const Color(0xFFFFAA44), 'hi'),
            const SizedBox(height: 6),

            // Tamil
            _langRow('🏛️', 'Tamil', phrase['ta']!, const Color(0xFF44DDAA), 'ta'),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideX(begin: 0.05);
  }

  Widget _langRow(String flag, String langName, String text, Color color, String langCode) {
    return GestureDetector(
      onTap: () => _speakPhrase(text, langCode),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          Icon(Icons.volume_up_rounded, color: color.withValues(alpha: 0.6), size: 20),
        ],
      ),
    );
  }

  Widget _emergencyNumber(String number, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(number, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9)),
      ],
    );
  }
}
