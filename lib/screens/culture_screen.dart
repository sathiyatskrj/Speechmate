import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/core/app_colors.dart';

class CultureScreen extends StatefulWidget {
  const CultureScreen({super.key});

  @override
  State<CultureScreen> createState() => _CultureScreenState();
}

class _CultureScreenState extends State<CultureScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndamanPalette.sandWhite,
      appBar: AppBar(
        backgroundColor: AndamanPalette.white,
        foregroundColor: AndamanPalette.stone,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AndamanPalette.border, width: 2)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("📖", style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              "Nicobar Encyclopedia",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AndamanPalette.stone,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AndamanPalette.oceanTeal,
          labelColor: AndamanPalette.oceanTeal,
          unselectedLabelColor: AndamanPalette.mist,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "History"),
            Tab(text: "People"),
            Tab(text: "Economy"),
            Tab(text: "Language"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildHistoryTab(),
            _buildPeopleTab(),
            _buildEconomyTab(),
            _buildLanguageTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            title: "The Emerald Archipelago",
            subtitle: "A land of pristine beaches, lush rainforests, and ancient traditions.",
            icon: Icons.public_rounded,
            color: AndamanPalette.bentoEmerald,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          _buildInfoTile(
            title: "Geography",
            content: "The Nicobar Islands lie in the eastern Indian Ocean, about 1,300 km from the mainland. They separate the Bay of Bengal from the Andaman Sea. Only 12 of the 22 islands are inhabited.",
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
          _buildInfoTile(
            title: "Key Islands",
            content: "• Car Nicobar (North) - Headquarters\n• Nancowry & Kamorta (Central)\n• Great Nicobar (South) - Largest",
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
          _buildInfoTile(
            title: "Climate",
            content: "Tropical and humid with heavy monsoon rains. The islands are covered in dense vegetation.",
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
     return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
           _buildTimelineItem(year: "1050 CE", title: "Nakkavaram", description: "Referenced in Chola inscriptions as 'Land of the Naked'."),
           _buildTimelineItem(year: "1756", title: "Danish Colony", description: "Colonized by Denmark, later sold to the British."),
           _buildTimelineItem(year: "1869", title: "British Era", description: "Became part of British India."),
           _buildTimelineItem(year: "1942", title: "WWII Occupation", description: "Occupied by Japanese forces during World War II."),
           _buildTimelineItem(year: "1947", title: "Indian Union", description: "Became part of independent India."),
           _buildTimelineItem(year: "2004", title: "Tsunami", description: "Devastated by the Indian Ocean Tsunami, reshaping the islands forever."),
        ].asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          return widget.animate().fadeIn(delay: (50 * idx).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
        }).toList(),
      ),
    );
  }

  Widget _buildPeopleTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            title: "The Holchu",
            subtitle: "Meaning 'Friend', reflecting their harmonious nature.",
            icon: Icons.groups_rounded,
            color: AndamanPalette.bentoAmber,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          _buildInteractiveCard(
            title: "Social Structure",
            content: "Nicobarese society is known for its strong community bonds. It has matrilineal leanings, where women enjoy high status and can traditionally be village chiefs.",
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
          _buildInteractiveCard(
            title: "Religion",
            content: "About 95% follow Protestant Christianity, a legacy of missionaries. However, this is uniquely blended with animistic roots, believing in spirits of the sea and forest (Iwi).",
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
          _buildInteractiveCard(
            title: "Festivals",
            content: "The 'Ossuary Feast' (Pig Festival) is central. It honors ancestors with night-long circular dances and grand feasts involving pork, yams, and coconuts.",
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildEconomyTab() {
    return GridView.count(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildGridCard("Coconuts", "The backbone of the economy. Used for food (Copra) and trade.", Icons.nature_rounded, AndamanPalette.bentoEmerald),
        _buildGridCard("Areca Nut", "Chewing betel nut is a widespread social custom.", Icons.grass_rounded, AndamanPalette.oceanTeal),
        _buildGridCard("Pigs", "A measure of wealth and essential for all festivals.", Icons.pets_rounded, AndamanPalette.bentoCoral),
        _buildGridCard("Fishing", "Essential for daily subsistence. Traditional canoes are used.", Icons.sailing_rounded, AndamanPalette.bentoSky),
        _buildGridCard("Pottery", "A specialty of Chowra Island, traded across the group.", Icons.category_rounded, AndamanPalette.bentoAmber),
        _buildGridCard("Canoes", "Hand-crafted dugout outrigger canoes (Hodi).", Icons.rowing_rounded, AndamanPalette.amber),
      ].asMap().entries.map((entry) {
        final idx = entry.key;
        final widget = entry.value;
        return widget.animate().fadeIn(delay: (50 * idx).ms, duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
      }).toList(),
    );
  }
  
  Widget _buildLanguageTab() {
     return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoTile(
            title: "Austroasiatic Family",
            content: "The Nicobarese languages belong to the Mon-Khmer branch of the Austroasiatic family, distinct from the Andamanese tribes.",
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 10),
          _buildInfoTile(
            title: "Dialects",
            content: "There are distinct dialects across islands: Car (most spoken), Chowra, Teressa, Nancowry, and Southern Nicobarese.",
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 10),
          Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: AndamanPalette.amberSoft,
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: AndamanPalette.amber.withOpacity(0.3), width: 2),
               boxShadow: const [
                 BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 4)),
               ],
             ),
             child: Column(
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Text("💡", style: TextStyle(fontSize: 20)),
                     const SizedBox(width: 8),
                     Text(
                       "Did You Know?",
                       style: GoogleFonts.outfit(
                         color: AndamanPalette.amber,
                         fontWeight: FontWeight.w800,
                         fontSize: 18,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 Text(
                   "The language has a complex vowel system with up to 14 vowels! It also has borrowed words from Portuguese and Malay due to trade history.",
                   textAlign: TextAlign.center,
                   style: GoogleFonts.inter(
                     color: AndamanPalette.stoneLight,
                     height: 1.5,
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ],
             ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1, end: 0)
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildHeroCard({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: const [
          BoxShadow(color: AndamanPalette.shadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AndamanPalette.stone,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AndamanPalette.mist,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AndamanPalette.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AndamanPalette.border, width: 2),
        boxShadow: const [
          BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AndamanPalette.oceanTeal,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              color: AndamanPalette.stoneLight,
              height: 1.5,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String year, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AndamanPalette.oceanTealSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AndamanPalette.borderTeal.withOpacity(0.5), width: 1.5),
            ),
            child: Text(
              year,
              style: GoogleFonts.inter(
                color: AndamanPalette.oceanTeal,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AndamanPalette.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AndamanPalette.border, width: 2),
                boxShadow: const [
                  BoxShadow(color: AndamanPalette.shadow, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AndamanPalette.stone,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: AndamanPalette.mist,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInteractiveCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AndamanPalette.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AndamanPalette.border, width: 2),
        boxShadow: const [
          BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: GoogleFonts.outfit(
              color: AndamanPalette.stone,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          iconColor: AndamanPalette.oceanTeal,
          collapsedIconColor: AndamanPalette.mist,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                content,
                style: GoogleFonts.inter(
                  color: AndamanPalette.stoneLight,
                  height: 1.5,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AndamanPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AndamanPalette.border, width: 2),
        boxShadow: const [
          BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AndamanPalette.stone,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AndamanPalette.mist,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
