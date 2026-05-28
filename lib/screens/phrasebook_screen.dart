import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/core/app_colors.dart';

class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  final TtsService _tts = TtsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Set<String> _favorites = {};

  final List<Map<String, String>> _phrases = [
    // Greetings
    {
      'nicobarese': 'Ka ha-un',
      'english': 'Hello / How are you?',
      'hindi': 'नमस्ते / आप कैसे हैं?',
      'phonetic': 'Ka ha-oon',
      'category': 'Greetings',
    },
    {
      'nicobarese': 'Harā-ö',
      'english': 'Goodbye',
      'hindi': 'अलविदा',
      'phonetic': 'Haraa-uh',
      'category': 'Greetings',
    },
    {
      'nicobarese': 'Kam-rö ha-ö',
      'english': 'Welcome',
      'hindi': 'स्वागत है',
      'phonetic': 'Kam-ruh ha-uh',
      'category': 'Greetings',
    },
    {
      'nicobarese': 'Tö-kā-ö',
      'english': 'Thank you',
      'hindi': 'धन्यवाद',
      'phonetic': 'Tuh-kaa-uh',
      'category': 'Greetings',
    },
    {
      'nicobarese': 'Ha-lö ö',
      'english': 'Please',
      'hindi': 'कृपया',
      'phonetic': 'Ha-luh uh',
      'category': 'Greetings',
    },
    {
      'nicobarese': 'Chā-ö nyō-ö',
      'english': 'Sorry',
      'hindi': 'माफ़ कीजिये',
      'phonetic': 'Chaa-uh nyoh-uh',
      'category': 'Greetings',
    },

    // Directions
    {
      'nicobarese': 'Kā-tö in-nī?',
      'english': 'Where is this?',
      'hindi': 'यह कहाँ है?',
      'phonetic': 'Kaa-tuh in-nee',
      'category': 'Directions',
    },
    {
      'nicobarese': 'Chū-ö tö hē-ö',
      'english': 'Go straight',
      'hindi': 'सीधे जाओ',
      'phonetic': 'Choo-uh tuh heh-uh',
      'category': 'Directions',
    },
    {
      'nicobarese': 'Lō-nö tö kō-lö',
      'english': 'Turn left',
      'hindi': 'बायें मुड़ें',
      'phonetic': 'Loh-nuh tuh koh-luh',
      'category': 'Directions',
    },
    {
      'nicobarese': 'Lō-nö tö fā-tö',
      'english': 'Turn right',
      'hindi': 'दायें मुड़ें',
      'phonetic': 'Loh-nuh tuh faa-tuh',
      'category': 'Directions',
    },
    {
      'nicobarese': 'Tö-vī-ö el-tī-a',
      'english': 'Is it far?',
      'hindi': 'क्या यह दूर है?',
      'phonetic': 'Tuh-vee-uh el-tee-a',
      'category': 'Directions',
    },

    // Market
    {
      'nicobarese': 'Kā-tö tö kō-hō-ö?',
      'english': 'How much is this?',
      'hindi': 'यह कितने का है?',
      'phonetic': 'Kaa-tuh tuh koh-hoh-uh',
      'category': 'Market',
    },
    {
      'nicobarese': 'Mō-hō-ö tö chī-nī',
      'english': 'Very expensive',
      'hindi': 'बहुत महंगा',
      'phonetic': 'Moh-hoh-uh tuh chee-nee',
      'category': 'Market',
    },
    {
      'nicobarese': 'In-nī tö sē-nö',
      'english': 'I want to buy this',
      'hindi': 'मैं इसे खरीदना चाहता हूँ',
      'phonetic': 'In-nee tuh seh-nuh',
      'category': 'Market',
    },
    {
      'nicobarese': 'Nyō-ö kō-fī',
      'english': 'Do you have coffee?',
      'hindi': 'क्या आपके पास कॉफी है?',
      'phonetic': 'Nyoh-uh koh-fee',
      'category': 'Market',
    },

    // Medical
    {
      'nicobarese': 'Chū-ö tö hō-sē-nö',
      'english': 'I am sick',
      'hindi': 'मैं बीमार हूँ',
      'phonetic': 'Choo-uh tuh hoh-seh-nuh',
      'category': 'Medical',
    },
    {
      'nicobarese': 'Hō-chī-a el-kō-lö',
      'english': 'My head hurts',
      'hindi': 'मेरे सिर में दर्द है',
      'phonetic': 'Hoh-chee-a el-koh-luh',
      'category': 'Medical',
    },
    {
      'nicobarese': 'Kā-tö dā-k-tō?',
      'english': 'Where is the doctor?',
      'hindi': 'डॉक्टर कहाँ हैं?',
      'phonetic': 'Kaa-tuh daak-toh',
      'category': 'Medical',
    },
    {
      'nicobarese': 'Lö-hō-nö e-hō-a',
      'english': 'Please help me',
      'hindi': 'कृपया मेरी मदद करें',
      'phonetic': 'Luh-hoh-nuh e-hoh-a',
      'category': 'Medical',
    },

    // Food & Dining
    {
      'nicobarese': 'Lō-tö e-nū-ö',
      'english': 'I want food',
      'hindi': 'मुझे खाना चाहिए',
      'phonetic': 'Loh-tuh e-noo-uh',
      'category': 'Food',
    },
    {
      'nicobarese': 'Dāk tö sū-a',
      'english': 'Give me water',
      'hindi': 'मुझे पानी दो',
      'phonetic': 'Daak tuh soo-a',
      'category': 'Food',
    },
    {
      'nicobarese': 'In-nī tö mō-nō-ö',
      'english': 'This is delicious',
      'hindi': 'यह स्वादिष्ट है',
      'phonetic': 'In-nee tuh moh-noh-uh',
      'category': 'Food',
    },
    {
      'nicobarese': 'Hō-kō-ö e-nū-ö',
      'english': 'Is the food ready?',
      'hindi': 'क्या खाना तैयार है?',
      'phonetic': 'Hoh-koh-uh e-noo-uh',
      'category': 'Food',
    },

    // Numbers
    {
      'nicobarese': 'Hē-a',
      'english': 'One',
      'hindi': 'एक',
      'phonetic': 'Heh-a',
      'category': 'Numbers',
    },
    {
      'nicobarese': 'Ā-a',
      'english': 'Two',
      'hindi': 'दो',
      'phonetic': 'Aa-a',
      'category': 'Numbers',
    },
    {
      'nicobarese': 'Lō-e',
      'english': 'Three',
      'hindi': 'तीन',
      'phonetic': 'Loh-eh',
      'category': 'Numbers',
    },
    {
      'nicobarese': 'Fā-t',
      'english': 'Four',
      'hindi': 'चार',
      'phonetic': 'Faa-t',
      'category': 'Numbers',
    },
    {
      'nicobarese': 'Tan-ē-a',
      'english': 'Five',
      'hindi': 'पाँच',
      'phonetic': 'Tan-ee-a',
      'category': 'Numbers',
    },
  ];

  final List<String> _categories = [
    'All',
    'Favorites',
    'Greetings',
    'Directions',
    'Market',
    'Medical',
    'Food',
    'Numbers',
  ];

  final Map<String, Color> _categoryColors = {
    'Greetings': AndamanPalette.bentoPurple,
    'Directions': AndamanPalette.bentoSky,
    'Market': AndamanPalette.bentoAmber,
    'Medical': AndamanPalette.bentoCoral,
    'Food': AndamanPalette.bentoEmerald,
    'Numbers': AndamanPalette.oceanTeal,
  };

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = (prefs.getStringList('phrasebook_favorites') ?? []).toSet();
    });
  }

  Future<void> _toggleFavorite(String nicobarese) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(nicobarese)) {
        _favorites.remove(nicobarese);
      } else {
        _favorites.add(nicobarese);
      }
    });
    await prefs.setStringList('phrasebook_favorites', _favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    // Filter phrases
    final filteredPhrases = _phrases.where((phrase) {
      final matchesSearch = phrase['nicobarese']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          phrase['english']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          phrase['hindi']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          phrase['phonetic']!.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_selectedCategory == 'All') {
        return matchesSearch;
      } else if (_selectedCategory == 'Favorites') {
        return matchesSearch && _favorites.contains(phrase['nicobarese']);
      } else {
        return matchesSearch && phrase['category'] == _selectedCategory;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AndamanPalette.sandWhite,
      appBar: AppBar(
        title: Text(
          'SITUATIONAL PHRASEBOOK',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 18,
            color: AndamanPalette.stone,
          ),
        ),
        centerTitle: true,
        backgroundColor: AndamanPalette.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AndamanPalette.border, width: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AndamanPalette.stone),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Categories Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AndamanPalette.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AndamanPalette.border, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: GoogleFonts.inter(
                    color: AndamanPalette.stone,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search phrases in Hindi, English, Nicobarese...',
                    hintStyle: GoogleFonts.inter(
                      color: AndamanPalette.mist,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AndamanPalette.mist),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AndamanPalette.mist),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Category Selector (Horizontal Scroll)
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        cat.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: isSelected ? AndamanPalette.oceanTeal : AndamanPalette.stoneLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AndamanPalette.oceanTealSoft,
                      backgroundColor: AndamanPalette.white,
                      checkmarkColor: AndamanPalette.oceanTeal,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AndamanPalette.borderTeal : AndamanPalette.border,
                          width: 2,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Phrase List
            Expanded(
              child: filteredPhrases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedCategory == 'Favorites' ? Icons.favorite_border_rounded : Icons.search_off_rounded,
                            size: 64,
                            color: AndamanPalette.mist,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategory == 'Favorites'
                                ? 'No bookmarked phrases yet!'
                                : 'No matching phrases found.',
                            style: GoogleFonts.inter(
                              color: AndamanPalette.stone,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategory == 'Favorites'
                                ? 'Tap the heart icon on any phrase card to save it here.'
                                : 'Try adjusting your search criteria.',
                            style: GoogleFonts.inter(
                              color: AndamanPalette.mist,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredPhrases.length,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemBuilder: (context, index) {
                        final phrase = filteredPhrases[index];
                        final isFav = _favorites.contains(phrase['nicobarese']);
                        final catColor = _categoryColors[phrase['category']] ?? AndamanPalette.oceanTeal;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AndamanPalette.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AndamanPalette.border,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AndamanPalette.shadow,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              children: [
                                // Colored accent line on the left side
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 6,
                                  child: Container(color: catColor),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header Row: Category Badge + Bookmark
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: catColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: catColor.withOpacity(0.25),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              phrase['category']!.toUpperCase(),
                                              style: GoogleFonts.inter(
                                                color: catColor,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 9,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              color: isFav ? AndamanPalette.reefCoral : AndamanPalette.mistLight,
                                              size: 22,
                                            ),
                                            onPressed: () => _toggleFavorite(phrase['nicobarese']!),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Nicobarese Phrase
                                      Text(
                                        phrase['nicobarese']!,
                                        style: GoogleFonts.outfit(
                                          color: AndamanPalette.stone,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                          letterSpacing: 0.3,
                                        ),
                                      ),

                                      // Phonetic Pronunciation Hint
                                      const SizedBox(height: 4),
                                      Text(
                                        '🗣️ "${phrase['phonetic']}"',
                                        style: GoogleFonts.inter(
                                          color: AndamanPalette.amber,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 12),
                                      const Divider(color: AndamanPalette.border, thickness: 1.5, height: 1),
                                      const SizedBox(height: 12),

                                      // Translations Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // English translation
                                                Text(
                                                  'EN: ${phrase['english']}',
                                                  style: GoogleFonts.inter(
                                                    color: AndamanPalette.stoneLight,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Hindi translation
                                                Text(
                                                  'HI: ${phrase['hindi']}',
                                                  style: GoogleFonts.inter(
                                                    color: AndamanPalette.mist,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Play Audio Button
                                          Material(
                                            color: AndamanPalette.oceanTealSoft,
                                            shape: const CircleBorder(),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.volume_up_rounded,
                                                color: AndamanPalette.oceanTeal,
                                                size: 22,
                                              ),
                                              onPressed: () {
                                                _tts.speakNicobarese(
                                                  phrase['nicobarese']!,
                                                  englishWord: phrase['english']!,
                                                  audioCategory: phrase['category']!.toLowerCase() == 'food' ? 'things' : phrase['category']!.toLowerCase(),
                                                );
                                              },
                                            ),
                                          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                           .shimmer(delay: 5.seconds, duration: 1.5.seconds, color: Colors.white.withOpacity(0.4)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
