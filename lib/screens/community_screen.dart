import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speechmate/widgets/background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/community_service.dart';
import 'package:speechmate/models/community_post.dart';
import 'package:speechmate/core/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();

  // Local state to track "liked" posts by this device/session
  final Set<String> _likedPostIds = {};
  
  // Admin State
  bool _isAdmin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Community Hub 🌏"),
            if (_isAdmin) ...[
                const SizedBox(width: 8),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                    child: const Text("ADMIN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                )
            ]
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
            if (!_isAdmin)
              IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                  tooltip: "Admin Login",
                  onPressed: _showAdminLoginDialog, // Login
              )
            else
              IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: "Logout Admin",
                  onPressed: () {
                      setState(() => _isAdmin = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin logged out")));
                  },
              ),
            IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                tooltip: "About Community Hub",
                onPressed: _showAboutDialog,
            )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostDialog,
        backgroundColor: _isAdmin ? Colors.redAccent : Colors.deepPurpleAccent,
        icon: Icon(_isAdmin ? Icons.campaign : Icons.edit),
        label: Text(_isAdmin ? "Admin Post" : "Contribute"),
      ),
      body: Background(
        colors: _isAdmin 
            ? const [Color(0xFF2b2b2b), Color(0xFF4a148c)] // Darker theme for admin
            : const [Color(0xFF89f7fe), Color(0xFF66a6ff)], 
        child: SafeArea(
          child: Column(
            children: [
                _buildSyncBanner(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _communityService.getPostsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Something went wrong: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      if (snapshot.data!.docs.isEmpty) {
                         return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 80, left: 16, right: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: snapshot.data!.docs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) return _buildTrendingSection();
                          
                          DocumentSnapshot doc = snapshot.data!.docs[index - 1];
                          CommunityPost post = CommunityPost.fromFirestore(doc);
                          
                          return _buildPostCard(post);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (EmptyState, SyncBanner, TrendingSection omitted for brevity, logic remains same)

  Widget _buildEmptyState() {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white70),
                  const SizedBox(height: 16),
                  const Text("No posts yet.", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: _showPostDialog,
                      child: const Text("Be the first to post!"),
                  )
              ],
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
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _isAdmin ? Colors.red : Colors.greenAccent, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 1.seconds).fadeOut(duration: 1.seconds),
                  const SizedBox(width: 8),
                  Text(_isAdmin ? "ADMIN MODE ACTIVE • REGULATING" : "LIVE • Global Community Feed", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildPostCard(CommunityPost post) {
    bool isLikedByMe = _likedPostIds.contains(post.id);
    String timeAgo = _formatTime(post.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _isAdmin && post.isVerified ? Border.all(color: Colors.green, width: 2) : null,
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
                  backgroundColor: Color(post.color),
                  child: Text(post.avatar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (post.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ],
                    ),
                    Text(post.role, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const Spacer(),
                if (_isAdmin) ...[
                    // ADMIN CONTROLS
                    IconButton(
                        icon: Icon(post.isVerified ? Icons.verified_user : Icons.verified_user_outlined, color: Colors.green),
                        tooltip: "Toggle Verify",
                        onPressed: () => _communityService.toggleVerification(post.id, post.isVerified),
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: "Delete Post",
                        onPressed: () => _confirmDelete(post.id),
                    ),
                ] else 
                    Text(timeAgo, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
            const SizedBox(height: 16),
            if (!_isAdmin)
            Row(
              children: [
                _buildActionButton(
                  icon: isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: isLikedByMe ? Colors.red : Colors.grey,
                  count: post.likes,
                  onTap: () {
                     setState(() {
                        if (isLikedByMe) {
                            _likedPostIds.remove(post.id);
                            _communityService.toggleLike(post.id, true);
                        } else {
                            _likedPostIds.add(post.id);
                            _communityService.toggleLike(post.id, false);
                        }
                     });
                  },
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  color: Colors.grey,
                  count: post.comments,
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

  void _confirmDelete(String postId) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text("Delete Post?"),
              content: const Text("This action cannot be undone."),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                  TextButton(
                      onPressed: () {
                          Navigator.pop(ctx);
                          _communityService.deletePost(postId);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted by Admin")));
                      },
                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                  )
              ],
          )
      );
  }

  String _formatTime(DateTime? timestamp) {
      if (timestamp == null) return "Just now";
      final diff = DateTime.now().difference(timestamp);
      if (diff.inMinutes < 1) return "Just now";
      if (diff.inHours < 1) return "${diff.inMinutes}m ago";
      if (diff.inDays < 1) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
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
              title: Text(_isAdmin ? "Admin Announcement 📢" : "Contribute to Hub ✍️"),
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
                              _communityService.addPost(
                                  author: _isAdmin ? "SpeechMate Admin" : "Guest User",
                                  role: _isAdmin ? "Administrator" : "Community Member",
                                  content: textController.text,
                                  avatar: _isAdmin ? "A" : "G",
                                  color: _isAdmin ? Colors.redAccent.value : Colors.teal.value
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Posting to cloud... ☁️"))
                              );
                          }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text("Post"),
                  )
              ],
          ),
      );
  }

  void _showAdminLoginDialog() {
      final TextEditingController userController = TextEditingController();
      final TextEditingController passController = TextEditingController();

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Admin Login 🛡️"),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      TextField(
                          controller: userController,
                          decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                          controller: passController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)),
                      )
                  ],
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  ElevatedButton(
                      onPressed: () {
                          if (userController.text.trim() == "Admin" && passController.text.trim() == "speechmate2026") {
                              Navigator.pop(context);
                              setState(() => _isAdmin = true);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome, Admin! Regulation Mode Active.")));
                          } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Credentials ❌")));
                          }
                      },
                      child: const Text("Login"),
                  )
              ],
          )
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
                          _buildInfoSection("What is this?", "A Live, connection to the global Speechmate community."),
                          _buildInfoSection("Real-Time?", "Yes! Posts appear instantly for everyone online."),
                          _buildInfoSection("Privacy", "No personal data is uploaded. Be kind and respectful."),
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



