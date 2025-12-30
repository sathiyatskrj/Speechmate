import 'package:flutter/material.dart';
import '../widgets/background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Background(
        colors: const [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                      image: const DecorationImage(
                          image: AssetImage('assets/icons/logo_main.png'),
                          fit: BoxFit.cover
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "SpeechMate",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "\"Where language barriers end.\"",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildSectionTitle("OUR MISSION"),
                _buildCard(
                  child: const Text(
                    "SpeechMate is a tribal language translation app designed to bridge the gap between students and teachers while preserving the rich linguistic and cultural heritage of the Nicobarese people.\n\nWe digitalize endangered languages to ensure they thrive in the modern world.",
                    style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                ),
                
                const SizedBox(height: 20),
                _buildSectionTitle("THE NICOBAR ISLANDS"),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.location_on, "Location", "750 km south of Andaman Islands"),
                      _buildInfoRow(Icons.people, "Population", "~37,000 (70% tribal)"),
                      _buildInfoRow(Icons.thermostat, "Climate", "Tropical monsoon, 2,600-2,800mm rainfall"),
                      _buildInfoRow(Icons.landscape, "Terrain", "Flat (Car Nicobar) to hilly (Mt. Thullier: 2,106 ft)"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionTitle("NICOBARESE LANGUAGES"),
                _buildCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("A unique Austroasiatic branch with ~30,000 speakers across 6-7 languages:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 12),
                      Text("• Car (Pū) - 20,000 speakers, lingua franca\n• Chowra (Sanenyo) - Pottery tradition\n• Teressa (Luro) - Central islands\n• Central Nicobarese - Nancowry, Camorta\n• Southern Nicobarese - Great Nicobar\n• Shompen - Rainforest isolate", 
                        style: TextStyle(height: 1.6, color: Colors.black87)),
                      SizedBox(height: 12),
                      Text("Unique Features:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("10-14 vowels, complex suffix systems, infixation, vowel-length contrasts, and taboo vocabulary traditions.", 
                        style: TextStyle(height: 1.5, color: Colors.black87)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionTitle("CULTURE & TRADITIONS"),
                _buildCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tuhet System:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("Joint family governance with matriarchal leadership. Village councils manage marriages, land, and resources.", style: TextStyle(height: 1.5, color: Colors.black87)),
                      SizedBox(height: 10),
                      Text("Pig Festival (Panuohonot):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("Multi-day celebration honoring the dead with sacred pig slaughter, feasting, traditional music (Duggera, Sumay), and palm wine.", style: TextStyle(height: 1.5, color: Colors.black87)),
                      SizedBox(height: 10),
                      Text("Crafts:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("Kareau carvings, pottery, basketwork, canoe building, and Kania spirit poles.", style: TextStyle(height: 1.5, color: Colors.black87)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionTitle("EDUCATION IMPACT"),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow("Total Schools", "306 (24 in tribal areas)"),
                      _buildStatRow("Total Students", "85,267 (6,018 tribal)"),
                      _buildStatRow("Girl Students", "48.38%"),
                      _buildStatRow("Teachers", "4,726 (1:18 ratio)"),
                      const Divider(height: 20),
                      const Text("Languages: English, Hindi, Tamil, Telugu, Bengali", style: TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionTitle("ACKNOWLEDGEMENTS"),
                _buildCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Built with ❤️ for Hack For Social Cause VBYLD 2026", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 10),
                      Text("Special thanks to the tribal communities of Nicobar for their invaluable cultural knowledge and to all educators working to preserve indigenous languages.", 
                        style: TextStyle(height: 1.5, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2C3E50)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        ],
      ),
    );
  }
}
