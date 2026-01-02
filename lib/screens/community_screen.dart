import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/widgets/background.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Initial Mock Data
  List<Map<String, dynamic>> _posts = [
     {
      "author": "SpeechMate Connect",
      "role": "Admin",
      "avatar": "A",
      "color": 0xFF2196F3, // Colors.blue.value
      "content": "Welcome to the Community Hub! Connect, share, and learn together. 🌏❤️",
      "likes": 156,
      "comments": 42,
      "time": "1 day ago",
      "isLiked": true,
      "isVerified": true,
    },
    {
      "author": "Sneha Gosh",
      "role": "Teacher Level 5",
      "avatar": "S",
      "color": 0xFF9C27B0, // Colors.purple.value
      "content": "Just finished Level 5! The new words for 'School' are so helpful. 🏫✨",
      "likes": 24,
      "comments": 5,
      "time": "2 hrs ago",
      "isLiked": false,
      "isVerified": true,
    },
    {
      "author": "Gladys",
      "role": "Student",
      "avatar": "R",
      "color": 0xFFFF9800, // Colors.orange.value
      "content": "Can anyone help me pronounce 'Möhakööp'? 🤔",
      "likes": 12,
      "comments": 8,
      "time": "4 hrs ago",
      "isLiked": false,
      "isVerified": false,
    },
    {
      "author": "Kunal Patel",
      "role": "Teacher Level 2",
      "avatar": "P",
      "color": 0xFFE91E63, // Colors.pink.value
      "content": "I shared a new quiz on 'Nature'. Check it out!",
      "likes": 8,
      "comments": 1,
      "time": "5 hrs ago",
      "isLiked": false,
      "isVerified": false,
    },
    {
      "author": "Rohan (Elder)",
      "role": "Native Speaker",
      "avatar": "Ro",
      "color": 0xFF009688, // Colors.teal.value
      "content": "Suggestion: We should add the word for 'Cycloned' (Pū-yö). It is important for our history. 🌪️",
      "likes": 45,
      "comments": 12,
      "time": "6 hrs ago",
      "isLiked": false,
      "isVerified": true,
    },
    {
      "author": "Anjali",
      "role": "Student",
      "avatar": "An",
      "color": 0xFF795548, // Colors.brown.value
      "content": "Found a missing word! 'Boat' is called 'Kū-ö' in my village dialect. 🛶",
      "likes": 32,
      "comments": 4,
      "time": "8 hrs ago",
      "isLiked": true,
      "isVerified": false,
    },
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedPosts = prefs.getString('community_posts');
    if (storedPosts != null) {
      setState(() {
        _posts = List<Map<String, dynamic>>.from(jsonDecode(storedPosts));
        _isLoading = false;
      });
    } else {
        setState(() => _isLoading = false);
    }
  }

  Future<void> _savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('community_posts', jsonEncode(_posts));
  }

  Future<void> _addPost(String content) async {
      // Simulate Network Delay
      showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white))
      );
      
      await Future.delayed(const Duration(seconds: 1)); // Fake network lag
      Navigator.pop(context); // Close loader

      setState(() {
          _posts.insert(0, {
              "author": "You",
              "role": "Contributor",
              "avatar": "Y",
              "color": Colors.green.value,
              "content": content,
              "likes": 0,
              "comments": 0,
              "time": "Just now",
              "isLiked": false,
              "isVerified": false,
          });
      });
      _savePosts();
      
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Posted to Community Hub 🚀"))
      );
  }

  void _toggleLike(int index) {
    setState(() {
      if (_posts[index]['isLiked'] == true) {
        _posts[index]['likes']--;
        _posts[index]['isLiked'] = false;
      } else {
        _posts[index]['likes']++;
        _posts[index]['isLiked'] = true;
      }
    });
    _savePosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Community Hub 🌏"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
            IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                tooltip: "About Community Hub",
                onPressed: _showAboutDialog,
            )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostDialog,
        backgroundColor: Colors.deepPurpleAccent,
        icon: const Icon(Icons.edit),
        label: const Text("Contribute"),
      ),
      body: Background(
        colors: const [Color(0xFF89f7fe), Color(0xFF66a6ff)], 
        child: SafeArea(
          child: Column(
            children: [
                _buildSyncBanner(),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 80, left: 16, right: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _posts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) return _buildTrendingSection();
                          return _buildPostCard(_posts[index - 1], index - 1);
                        },
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncBanner() {
      return Container(
          width: double.infinity,
          color: Colors.white.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 1.seconds).fadeOut(duration: 1.seconds),
                  const SizedBox(width: 8),
                  const Text("Live Sync Active • Decentralized Node", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
          ),
      );
  }

  Widget _buildTrendingSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text("Trending Topics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildTag("#Level1Challenge"),
              _buildTag("#WordOfTheDay"),
              _buildTag("#Nicobarese"),
              _buildTag("#Speechmate"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.deepPurple.withOpacity(0.05),
      labelStyle: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
      side: BorderSide.none,
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(post['color']),
                  child: Text(post['avatar'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(post['author'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (post['isVerified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ],
                    ),
                    Text(post['role'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Text(post['time'], style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(post['content'], style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionButton(
                  icon: post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                  color: post['isLiked'] ? Colors.red : Colors.grey,
                  count: post['likes'],
                  onTap: () => _toggleLike(index),
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  color: Colors.grey,
                  count: post['comments'],
                  onTap: () {},
                ),
                const Spacer(),
                const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildActionButton({required IconData icon, required Color color, required int count, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(
            "$count",
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showPostDialog() {
      final TextEditingController textController = TextEditingController();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Contribute to Hub ✍️"),
              content: TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: "Share a word, phrase, or question...",
                      border: OutlineInputBorder(),
                  ),
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  ElevatedButton.icon(
                      onPressed: () {
                          if (textController.text.isNotEmpty) {
                              Navigator.pop(context);
                              _addPost(textController.text);
                          }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text("Post"),
                  )
              ],
          ),
      );
  }

  void _showAboutDialog() {
      showDialog(
          context: context,
          builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          const Text("About Community Hub", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          const SizedBox(height: 15),
                          _buildInfoSection("What is this?", "The Community Hub is a decentralized, offline-capable collaborative space where native speakers, teachers, and students contribute, validate, and preserve tribal language data ethically."),
                          _buildInfoSection("Why needed?", "Tribal languages are low-resource. This hub allows native speakers to contribute words ensuring linguistic authenticity."),
                          _buildInfoSection("Is it online?", "It is offline-first. Contributions are stored locally and synced when connectivity is available."),
                          _buildInfoSection("Privacy", "No data is uploaded without consent. Voice samples are recorded only after permission."),
                          const SizedBox(height: 20),
                          Center(
                              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))
                          )
                      ],
                  ),
              ),
          ),
      );
  }

  Widget _buildInfoSection(String title, String content) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(content, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
              ],
          ),
      );
  }
}



