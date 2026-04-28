import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/community_service.dart';
import 'package:speechmate/models/community_post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/features/gamification/gamification_service.dart';
import 'package:speechmate/services/progress_service.dart';
import 'package:speechmate/core/app_colors.dart';
import 'package:crypto/crypto.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();

  // Admin State
  bool _isAdmin = false;
  String? _currentUid;

  // Posts
  List<CommunityPost> _posts = [];
  Set<String> _likedPostIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPosts();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUid = prefs.getString('local_device_id') ?? 'anonymous_device';
    });
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final rawPosts = await _communityService.getPosts();
      final likedIds = await _communityService.getLikedPosts();
      
      List<CommunityPost> allPosts = [];
      
      // Add seed posts if no local posts exist yet
      if (rawPosts.isEmpty) {
        allPosts = _getSeedPosts();
      } else {
        allPosts = rawPosts.map((m) => CommunityPost.fromMap(m)).toList();
      }
      
      // Always include seed posts that aren't already in the list
      final seedPosts = _getSeedPosts();
      final existingIds = allPosts.map((p) => p.id).toSet();
      for (final seed in seedPosts) {
        if (!existingIds.contains(seed.id)) {
          allPosts.add(seed);
        }
      }
      
      // Sort newest first
      allPosts.sort((a, b) => (b.timestamp ?? DateTime(2000)).compareTo(a.timestamp ?? DateTime(2000)));
      
      if (mounted) {
        setState(() {
          _posts = allPosts;
          _likedPostIds = likedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Community] Load error: $e');
      if (mounted) {
        setState(() {
          _posts = _getSeedPosts();
          _isLoading = false;
        });
      }
    }
  }

  List<CommunityPost> _getSeedPosts() {
    return [
      CommunityPost(
        id: 'seed_1',
        author: 'SpeechMate Admin',
        role: 'Administrator',
        content: 'Welcome to the Nicobarese learning community! 🌏\n\nFeel free to ask questions, share words you\'ve learned, and help verify pronunciations. Together we are preserving an endangered language for future generations.',
        avatar: 'A',
        color: Colors.redAccent.value,
        likes: 42,
        likedBy: [],
        comments: 5,
        isVerified: true,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
      ),
      CommunityPost(
        id: 'seed_2',
        author: 'Pratik B.',
        role: 'Core Developer',
        content: 'Just pushed a major update to the AR translator! 📸 Now it detects objects in real-time and shows Nicobarese translations with bounding boxes. Try pointing your camera at everyday objects!',
        avatar: 'P',
        color: Colors.blueAccent.value,
        likes: 28,
        likedBy: [],
        comments: 8,
        isVerified: true,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      CommunityPost(
        id: 'seed_3',
        author: 'Dr. Sharma',
        role: 'Linguist',
        content: 'Did you know? Nicobarese has incredibly rich semantics related to island ecology. The word for "jungle" (Tōt) carries cultural weight far beyond its English translation. Check out the Nature Hub to explore more! 🌿',
        avatar: 'S',
        color: Colors.green.value,
        likes: 89,
        likedBy: [],
        comments: 14,
        isVerified: true,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
      CommunityPost(
        id: 'seed_4',
        author: 'Kunal P.',
        role: 'VBYLD 2026 Team',
        content: 'Our presentation at the nationals was incredible! 🇮🇳 Ranked 6th in India at VBYLD 2026. The judges were impressed by how SpeechMate preserves tribal languages completely offline. Proud to be part of this mission!',
        avatar: 'K',
        color: Colors.orangeAccent.value,
        likes: 156,
        likedBy: [],
        comments: 22,
        isVerified: true,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CommunityPost(
        id: 'seed_5',
        author: 'Sneha G.',
        role: 'Student • Nationals Team',
        content: 'Learned 15 new Nicobarese words today using the flashcard game! 🎲 The spaced repetition really helps. "Nöngūm" = Nose, "Tananga" = Ear. Who else is on a streak? 🔥',
        avatar: 'S',
        color: Colors.purpleAccent.value,
        likes: 34,
        likedBy: [],
        comments: 6,
        isVerified: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      CommunityPost(
        id: 'seed_6',
        author: 'Elder Mary',
        role: 'Nicobarese Community',
        content: 'I am very happy to see young people learning our language. When I was young, everyone spoke Nicobarese. Now only elders remember the old songs. This app gives me hope. 🙏',
        avatar: 'M',
        color: Colors.teal.value,
        likes: 201,
        likedBy: [],
        comments: 31,
        isVerified: true,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

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
                  onPressed: _showAdminLoginDialog,
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
        backgroundColor: _isAdmin ? Colors.redAccent : AppColors.studentAccent,
        icon: Icon(_isAdmin ? Icons.campaign : Icons.edit),
        label: Text(_isAdmin ? "Admin Post" : "Contribute", style: const TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isAdmin 
                ? [Colors.black87, Colors.black] 
                : [
                    AppColors.studentAccent.withValues(alpha: 0.8),
                    Colors.black
                  ],
          )
        ),
        child: SafeArea(
           child: Column(
            children: [
                _buildSyncBanner(),
                Expanded(
                  child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                    : _posts.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadPosts,
                          color: Colors.cyanAccent,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 10, bottom: 80, left: 16, right: 16),
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: _posts.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildTrendingSection();
                              
                              CommunityPost post = _posts[index - 1];
                              return _buildPostCard(post);
                            },
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
          color: Colors.white.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _isAdmin ? Colors.red : Colors.amberAccent, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 1.seconds).fadeOut(duration: 1.seconds),
                  const SizedBox(width: 8),
                  Text(_isAdmin ? "ADMIN MODE ACTIVE • REGULATING" : "OFFLINE MODE • Local Community Feed", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
          ),
      );
  }

  Widget _buildTrendingSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.studentAccent),
              const SizedBox(width: 8),
              const Text("Trending Topics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildTag("#VBYLD2026"),
              _buildTag("#NicobareseLearning"),
              _buildTag("#LanguagePreservation"),
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
      backgroundColor: AppColors.studentAccent.withValues(alpha: 0.2),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      side: const BorderSide(color: Colors.white24),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    bool isLikedByMe = _likedPostIds.contains(post.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: _isAdmin && post.isVerified ? Border.all(color: Colors.green, width: 2) : Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                        Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        if (post.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                        ],
                      ],
                    ),
                    Text(post.role, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
                const Spacer(),
                if (_isAdmin) ...[
                    IconButton(
                        icon: Icon(post.isVerified ? Icons.verified_user : Icons.verified_user_outlined, color: Colors.green),
                        tooltip: "Toggle Verify",
                        onPressed: () async {
                          await _communityService.toggleVerification(post.id, post.isVerified);
                          _loadPosts();
                        },
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: "Delete Post",
                        onPressed: () => _confirmDelete(post.id),
                    ),
                ] else 
                    Text(_formatTime(post.timestamp), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white)),
            const SizedBox(height: 16),
            if (!_isAdmin)
              Row(
                children: [
                   _buildActionButton(
                      icon: isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      color: isLikedByMe ? Colors.red : Colors.grey,
                      count: post.likes,
                      onTap: () async {
                         await _communityService.toggleLike(post.id, isLikedByMe);
                         _loadPosts();
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
                      onPressed: () async {
                          Navigator.pop(ctx);
                          await _communityService.deletePost(postId);
                          _loadPosts();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted by Admin")));
                          }
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
                      onPressed: () async {
                          if (textController.text.isNotEmpty) {
                              Navigator.pop(context);
                              await _communityService.addPost(
                                  author: _isAdmin ? "SpeechMate Admin" : "Guest User",
                                  role: _isAdmin ? "Administrator" : "Community Member",
                                  content: textController.text,
                                  avatar: _isAdmin ? "A" : "G",
                                  color: _isAdmin ? Colors.redAccent.value : Colors.teal.value
                              );
                              // Award XP for contributing
                              ProgressService().recordCommunityPost().then((_) {
                                  GamificationService.refresh();
                              });
                              _loadPosts();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Posted to community! ✍️ +XP!"))
                                );
                              }
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
                          // SHA-256 hashed credentials — no plaintext in source
                          final userHash = sha256.convert(utf8.encode(userController.text.trim())).toString();
                          final passHash = sha256.convert(utf8.encode(passController.text.trim())).toString();
                          const expectedUserHash = 'c1c224b03cd9bc7b6a86d77f5dace40191766c485cd55dc48caf9ac873335d6f';
                          const expectedPassHash = '4bd1f55a7f13a2db3c7884164ae85adf727cc461396298199b8641981c218e88';
                          if (userHash == expectedUserHash && passHash == expectedPassHash) {
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
                          _buildInfoSection("What is this?", "A community hub for Speechmate learners to share progress and language knowledge."),
                          _buildInfoSection("Offline Mode", "Currently running in offline mode. Posts are stored locally. Cloud sync will be enabled in a future update."),
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
