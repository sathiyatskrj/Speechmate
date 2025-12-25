import 'package:flutter/material.dart';
import '../widgets/background.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _posts = [
    {
      "author": "Sarah M.",
      "role": "Teacher Level 5",
      "avatar": "S",
      "color": Colors.purple,
      "content": "Just finished Level 5! The new words for 'School' are so helpful. 🏫✨",
      "likes": 24,
      "comments": 5,
      "time": "2 hrs ago",
      "isLiked": false,
    },
    {
      "author": "Rahul K.",
      "role": "Student",
      "avatar": "R",
      "color": Colors.orange,
      "content": "Can anyone help me pronounce 'Möhakööp'? 🤔",
      "likes": 12,
      "comments": 8,
      "time": "4 hrs ago",
      "isLiked": false,
    },
     {
      "author": "Speechmate Team",
      "role": "Admin",
      "avatar": "A",
      "color": Colors.blue,
      "content": "Welcome to the Community Hub! Connect, share, and learn together. 🌏❤️",
      "likes": 156,
      "comments": 42,
      "time": "1 day ago",
      "isLiked": true,
    },
    {
      "author": "Priya S.",
      "role": "Teacher Level 2",
      "avatar": "P",
      "color": Colors.pink,
      "content": "I shared a new quiz on 'Nature'. Check it out!",
      "likes": 8,
      "comments": 1,
      "time": "5 hrs ago",
      "isLiked": false,
    },
  ];

  void _toggleLike(int index) {
    setState(() {
      if (_posts[index]['isLiked']) {
        _posts[index]['likes']--;
        _posts[index]['isLiked'] = false;
      } else {
        _posts[index]['likes']++;
        _posts[index]['isLiked'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Community Hub 🌏"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post creation coming soon!")),
          );
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.edit),
        label: const Text("New Post"),
      ),
      body: Background(
        colors: const [Color(0xFF89f7fe), Color(0xFF66a6ff)], // Fresh Blue Gradient
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
          itemCount: _posts.length + 1, // +1 for Trending header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildTrendingSection();
            }
            final post = _posts[index - 1];
            return _buildPostCard(post, index - 1);
          },
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text("Trending Topics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.blue.withOpacity(0.1),
      labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: post['color'],
                child: Text(post['avatar'], style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['author'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(post['role'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(post['time'], style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(post['content'], style: const TextStyle(fontSize: 15, height: 1.4)),
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
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
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
}
