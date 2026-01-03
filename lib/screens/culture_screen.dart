import 'package:flutter/material.dart';
import '../widgets/background.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Nicobar Encyclopedia", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "History"),
            Tab(text: "People"),
            Tab(text: "Economy"),
            Tab(text: "Language"),
          ],
        ),
      ),
      body: Background(
        colors: const [Color(0xFF141E30), Color(0xFF243B55)], // Teacher Dash Theme
        child: SafeArea(
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
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            title: "The Emerald Archipelago",
            subtitle: "A land of pristine beaches, lush rainforests, and ancient traditions.",
            icon: Icons.public,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 20),
          _buildInfoTile(
            title: "Geography",
            content: "The Nicobar Islands lie in the eastern Indian Ocean, about 1,300 km from the mainland. They separate the Bay of Bengal from the Andaman Sea. Only 12 of the 22 islands are inhabited.",
          ),
          _buildInfoTile(
            title: "Key Islands",
            content: "• Car Nicobar (North) - Headquarters\n• Nancowry & Kamorta (Central)\n• Great Nicobar (South) - Largest",
          ),
          _buildInfoTile(
            title: "Climate",
            content: "Tropical and humid with heavy monsoon rains. The islands are covered in dense vegetation.",
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
     return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
           _buildTimelineItem(year: "1050 CE", title: "Nakkavaram", description: "Referenced in Chola inscriptions as 'Land of the Naked'."),
           _buildTimelineItem(year: "1756", title: "Danish Colony", description: "Colonized by Denmark, later sold to the British."),
           _buildTimelineItem(year: "1869", title: "British Era", description: "Became part of British India."),
           _buildTimelineItem(year: "1942", title: "WWII Occupation", description: "Occupied by Japanese forces during World War II."),
           _buildTimelineItem(year: "1947", title: "Indian Union", description: "Became part of independent India."),
           _buildTimelineItem(year: "2004", title: "Tsunami", description: "Devastated by the Indian Ocean Tsunami, reshaping the islands forever."),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            title: "The Holchu",
            subtitle: "Meaning 'Friend', reflecting their harmonious nature.",
            icon: Icons.groups,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 20),
          _buildInteractiveCard(
            title: "Social Structure",
            content: "Nicobarese society is known for its strong community bonds. It has matrilineal leanings, where women enjoy high status and can traditionally be village chiefs.",
          ),
          _buildInteractiveCard(
            title: "Religion",
            content: "About 95% follow Protestant Christianity, a legacy of missionaries. However, this is uniquely blended with animistic roots, believing in spirits of the sea and forest (Iwi).",
          ),
          _buildInteractiveCard(
            title: "Festivals",
            content: "The 'Ossuary Feast' (Pig Festival) is central. It honors ancestors with night-long circular dances and grand feasts involving pork, yams, and coconuts.",
          ),
        ],
      ),
    );
  }

  Widget _buildEconomyTab() {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildGridCard("Coconuts", "The backbone of the economy. Used for food (Copra) and trade.", Icons.nature, Colors.tealAccent),
        _buildGridCard("Areca Nut", "Chewing betel nut is a widespread social custom.", Icons.grass, Colors.lightGreenAccent),
        _buildGridCard("Pigs", "A measure of wealth and essential for all festivals.", Icons.pets, Colors.pinkAccent),
        _buildGridCard("Fishing", "Essential for daily subsistence. Traditional canoes are used.", Icons.sailing, Colors.blueAccent),
        _buildGridCard("Pottery", "A specialty of Chowra Island, traded across the group.", Icons.category, Colors.brown),
        _buildGridCard("Canoes", "Hand-crafted dugout outrigger canoes (Hodi).", Icons.rowing, Colors.amberAccent),
      ],
    );
  }
  
  Widget _buildLanguageTab() {
     return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoTile(
            title: "Austroasiatic Family",
            content: "The Nicobarese languages belong to the Mon-Khmer branch of the Austroasiatic family, distinct from the Andamanese tribes.",
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            title: "Dialects",
            content: "There are distinct dialects across islands: Car (most spoken), Chowra, Teressa, Nancowry, and Southern Nicobarese.",
          ),
          const SizedBox(height: 10),
          Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.05),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: Colors.white.withOpacity(0.1)),
             ),
             child: const Column(
               children: [
                 Text("Did You Know?", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                 SizedBox(height: 10),
                 Text(
                   "The language has a complex vowel system with up to 14 vowels! It also has borrowed words from Portuguese and Malay due to trade history.",
                   textAlign: TextAlign.center,
                   style: TextStyle(color: Colors.white70),
                 ),
               ],
             ),
          )
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildHeroCard({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white, height: 1.5)),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(year, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(description, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInteractiveCard({required String title, required String content}) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 15),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconColor: Colors.cyanAccent,
        collapsedIconColor: Colors.white54,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(content, style: const TextStyle(color: Colors.white70, height: 1.5)),
          )
        ],
      ),
    );
  }

  Widget _buildGridCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
