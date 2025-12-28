import 'package:flutter/material.dart';
import 'package:speechmate/widgets/glass_container.dart'; // Ensure this matches actual path or use inline glass if needed

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Deep dark background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- HERO HEADER ---
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E2C),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "The Nicobar Legacy",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.3,
                    child: Icon(Icons.waves, size: 150, color: Colors.cyanAccent),
                  ),
                ),
              ),
            ),
          ),

          // --- CONTENT SLIVERS ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // EMOTIONAL INTRO
                   _buildSectionTitle("Speechmate", Icons.favorite, Colors.redAccent),
                   const SizedBox(height: 5),
                   const Text(
                     "Where the language barriers end.",
                     style: TextStyle(
                       color: Colors.cyanAccent,
                       fontSize: 16,
                       fontWeight: FontWeight.bold,
                       fontStyle: FontStyle.italic,
                     ),
                   ),
                   const SizedBox(height: 15),
                   _buildGlassCard(
                     child: const Text(
                       "Language is the soul of a culture. When a language fades, a unique way of seeing the world vanishes with it.\n\n"
                       "The Nicobarese dialects—complex, musical, and ancient—are whispers from our ancestors. Speechmate is not just an app; it is a bridge. "
                       "A bridge between the wisdom of the 'Tuhet' and the digital future of our schools.\n\n"
                       "We built this to ensure that while we move forward, we never leave our identity behind.",
                       style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6, fontStyle: FontStyle.italic),
                     ),
                   ),
                   const SizedBox(height: 30),

                   // NICOBAR ISLANDS
                   _buildSectionTitle("The Land of 37,000 Souls", Icons.landscape, Colors.greenAccent),
                   _buildInfoRow("Archipelago", "750 km south of Andamans"),
                   _buildInfoRow("Population", "~37,000 (70% Tribal)"),
                   _buildInfoRow("Terrain", "Flat Car Nicobar to Hilly Great Nicobar"),
                   _buildInfoRow("Climate", "Tropical Monsoon (2600mm Rain)"),
                   
                   const SizedBox(height: 30),

                   // LANGUAGE
                   _buildSectionTitle("A Linguistic Treasure", Icons.record_voice_over, Colors.orangeAccent),
                   _buildGlassCard(
                     child: const Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text("Austroasiatic Branch • 6-7 Languages", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                         SizedBox(height: 10),
                         Text("• Car (Pū): The Lingua Franca (~20,000 speakers)", style: TextStyle(color: Colors.white70)),
                         Text("• Unique: 10-14 distinct vowels!", style: TextStyle(color: Colors.white70)),
                         Text("• Taboo Vocab: Names of the deceased are banned, forcing rapid language evolution.", style: TextStyle(color: Colors.yellowAccent)),
                       ],
                     ),
                   ),

                   const SizedBox(height: 30),

                   // PEOPLE & SOCIETY
                   _buildSectionTitle("The Tuhet System", Icons.people_outline, Colors.purpleAccent),
                   _buildGlassCard(
                     child: const Text(
                       "At the heart of Nicobarese society is the 'Tuhet'—a joint family unit governing land and resources. "
                       "Men and women enjoy equality, with a rich history of matriarchal chiefs like Islon.",
                       style: TextStyle(color: Colors.white70, height: 1.5),
                     ),
                   ),
                   
                   const SizedBox(height: 30),

                   // CULTURE
                   _buildSectionTitle("Culture & Traditions", Icons.celebration, Colors.pinkAccent),
                   SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     physics: const BouncingScrollPhysics(),
                     child: Row(
                       children: [
                         _buildCultureCard("Pig Festival", "Ossuary Feast\nHonoring Ancestors", Icons.restaurant),
                         const SizedBox(width: 15),
                         _buildCultureCard("Hodi Crafts", "Canoe Building\nMaster Seafarers", Icons.sailing),
                         const SizedBox(width: 15),
                         _buildCultureCard("Kareau", "Spirit Statues\nWood Carving", Icons.psychology),
                       ],
                     ),
                   ),

                   const SizedBox(height: 30),

                   // EDUCATION STATS - GRID
                   _buildSectionTitle("Education Profile (2024-25)", Icons.school, Colors.blueAccent),
                   const SizedBox(height: 10),
                   GridView.count(
                     crossAxisCount: 2,
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     childAspectRatio: 1.5,
                     crossAxisSpacing: 10,
                     mainAxisSpacing: 10,
                     children: [
                        _buildStatCard("408", "Schools"),
                        _buildStatCard("98.6%", "GER (Primary)"),
                        _buildStatCard("1:12", "Teacher-Pupil Ratio"),
                        _buildStatCard("69%", "Female Teachers"),
                     ],
                   ),
                   const SizedBox(height: 10),
                   _buildGlassCard(
                      child: const Text(
                        "Despite isolation, we boast a Teacher-Pupil ratio significantly better than the national average (1:24). Education is our path forward.",
                         style: TextStyle(color: Colors.white70, fontSize: 13),
                      )
                   ),
                   
                   const SizedBox(height: 50),
                   Center(
                     child: Text(
                       "For the Hackathon. For the People.",
                       style: TextStyle(color: Colors.white12, fontSize: 12, letterSpacing: 2),
                     ),
                   ),
                   const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCultureCard(String title, String subtitle, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amberAccent, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
