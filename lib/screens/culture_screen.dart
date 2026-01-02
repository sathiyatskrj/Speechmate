import 'package:flutter/material.dart';
import '../widgets/background.dart';

class CultureScreen extends StatelessWidget {
  const CultureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Nicobar Culture 🌴", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Background(
        colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(),
                const SizedBox(height: 30),
                _buildSectionTitle("The People & Society"),
                _buildInfoCard(
                  icon: Icons.groups_rounded,
                  title: "Holchu (The Friend)",
                  content: "The Nicobarese call themselves 'Holchu', meaning Friend. Their society is built on harmony, hospitality, and strong communal values. Interestingly, leadership has often been matrilineal, where women hold high status and can be village chiefs.",
                  color: Colors.orangeAccent,
                ),
                
                const SizedBox(height: 20),
                _buildSectionTitle("Traditions & Festivals"),
                _buildInfoCard(
                  icon: Icons.festival_rounded,
                  title: "The Ossuary (Pig) Festival",
                  content: "A major event honoring ancestors, featuring night-long circular dances in traditional costumes and large communal feasts. Pigs are central to their economy and rituals.",
                  color: Colors.pinkAccent,
                ),

                const SizedBox(height: 20),
                _buildSectionTitle("Geography & Nature"),
                _buildInfoCard(
                  icon: Icons.landscape_rounded,
                  title: "Emerald Islands",
                  content: "The archipelago consists of 22 islands (12 inhabited) in the Bay of Bengal. From the flat, fertile Car Nicobar to the rugged Mount Thullier (642m) on Great Nicobar, the land is tropical and lush.",
                  color: Colors.greenAccent,
                ),

                const SizedBox(height: 20),
                _buildSectionTitle("Livelihood"),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    _buildMiniCard("Agriculture", "Coconuts, Areca Nut", Icons.agriculture),
                    _buildMiniCard("Crafts", "Canoes, Wood Carving", Icons.handyman),
                    _buildMiniCard("Fishing", "Reef fishing, Hunting", Icons.sailing),
                    _buildMiniCard("Economy", "Copra (Dried Coconut)", Icons.monetization_on),
                  ],
                ),
                
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "Source: Nicobar District Administration & Britannica",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
      ),
      child: const Column(
        children: [
          Icon(Icons.public, size: 60, color: Colors.white),
          SizedBox(height: 15),
          Text(
            "Discover The Islands",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "A mix of animist traditions, Christian faith, and a deep bond with nature.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(content, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
