import 'package:flutter/material.dart';
import 'package:speechmate/screens/word_management_screen.dart';
import 'package:speechmate/screens/about_screen.dart';
import '../widgets/background.dart';
import '../widgets/search_bar.dart';
import '../widgets/translation_card.dart';
import '../services/dictionary_service.dart';

class TeacherDash extends StatefulWidget {
  const TeacherDash({super.key});

  @override
  State<TeacherDash> createState() => _TeacherDashState();
}

class _TeacherDashState extends State<TeacherDash> {
  final TextEditingController _searchController = TextEditingController();
  final DictionaryService _dictionaryService = DictionaryService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  bool _searchedNicobarese = false;

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus();
    if (_searchController.text.isEmpty) return;

    setState(() => _isLoading = true);

    // 1. Direct Search
    var searchResult = await _dictionaryService.searchEverywhere(
      _searchController.text,
    );
    
    // 2. NLP Translation Fallback
    if (searchResult == null) {
        searchResult = await _dictionaryService.translateSentence(_searchController.text);
    }

    if (mounted) {
      setState(() {
        _result = searchResult;
        
        if (searchResult != null) {
          if (searchResult!.containsKey('_searchedNicobarese')) {
              _searchedNicobarese = searchResult!['_searchedNicobarese'];
          } else if (searchResult!.containsKey('_isGenerated')) {
             _searchedNicobarese = false; 
          } else {
              final query = _searchController.text.trim().toLowerCase();
              _searchedNicobarese =
                  searchResult!['nicobarese'].toString().toLowerCase() == query;
          }
        } else {
          _searchedNicobarese = false;
        }
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: const [Color(0xFF141E30), Color(0xFF243B55)], // Professional Dark Navy
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back,",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Text(
                          "Teacher Panel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.cyanAccent,
                      child: Icon(Icons.person, color: Colors.black),
                    )
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Analytics Cards
                const Text(
                  "OVERVIEW",
                  style: TextStyle(
                    color: Colors.cyanAccent, 
                    fontWeight: FontWeight.w700, 
                    letterSpacing: 1.2
                  ),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard("Students", "125", Icons.group, Colors.blue),
                      const SizedBox(width: 15),
                      _buildStatCard("Words Learned", "8,234", Icons.auto_stories, Colors.purple),
                      const SizedBox(width: 15),
                      _buildStatCard("Avg. Time", "45m", Icons.timer, Colors.orange),
                    ],
                  ),
                ),
                
                const SizedBox(height: 35),

                // TRANSLATION TOOL (HACKATHON FEATURE)
                const Text(
                  "QUICK TRANSLATE",
                  style: TextStyle(
                    color: Colors.cyanAccent, 
                    fontWeight: FontWeight.w700, 
                    letterSpacing: 1.2
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                   ),
                   child: Column(
                     children: [
                        Search(
                          controller: _searchController, 
                          onSearch: _performSearch, 
                          onClear: _clearSearch, 
                          onMicTap: () {}, // No mic needed for teacher maybe? Or implement slightly different?
                          // Assuming Search widget handles mic tap optionality? 
                          // If Search widget REQUIRES mic tap, I'll provide empty function or one that shows 'Not for Teacher'
                          // Let's implement basic mic if needed, but for now empty is safe.
                        ),
                        if (_isLoading)
                           const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.cyanAccent)),
                        
                        if (_result != null)
                           Padding(
                             padding: const EdgeInsets.only(top: 15),
                             child: TranslationCard(
                                nicobarese: _result!['nicobarese'],
                                english: _result!['english'] ?? _result!['text'] ?? "",
                                searchedNicobarese: _searchedNicobarese,
                                isError: false,
                                showSpeaker: false, // Keep it simple for teacher dash
                             ),
                           )
                        else if (_searchController.text.isNotEmpty && !_isLoading && _result == null)
                            const Padding(padding: EdgeInsets.all(10), child: Text("No result found.", style: TextStyle(color: Colors.white54))),
                     ],
                   ),
                ),

                const SizedBox(height: 35),

                // Management Section
                const Text(
                  "MANAGEMENT",
                  style: TextStyle(
                    color: Colors.cyanAccent, 
                    fontWeight: FontWeight.w700, 
                    letterSpacing: 1.2
                  ),
                ),
                const SizedBox(height: 15),
                
                _buildActionTile(
                  context,
                  title: "Manage Dictionary",
                  subtitle: "Add, edit or remove words",
                  icon: Icons.book,
                  color: Colors.pinkAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WordManagementScreen())),
                ),
                _buildActionTile(
                  context,
                  title: "Student Progress",
                  subtitle: "View individual reports",
                  icon: Icons.bar_chart,
                  color: Colors.greenAccent,
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feature Enabled for Demo")));
                  },
                ),
                _buildActionTile(
                  context,
                  title: "Class Settings",
                  subtitle: "Permissions and access",
                  icon: Icons.settings,
                  color: Colors.blueAccent,
                  onTap: () {},
                ),
                 _buildActionTile(
                  context,
                  title: "About App",
                  subtitle: "Version & Mission",
                  icon: Icons.info_outline,
                  color: Colors.white70,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),

                const SizedBox(height: 30),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
      ),
    );
  }
}
