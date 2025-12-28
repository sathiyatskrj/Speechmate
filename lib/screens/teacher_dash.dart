import 'package:flutter/material.dart';
import 'package:speechmate/screens/word_management_screen.dart';
import 'package:speechmate/screens/about_screen.dart';
import '../widgets/background.dart';

class TeacherDash extends StatelessWidget {
  const TeacherDash({super.key});

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
