import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speechmate/core/app_colors.dart';
import 'package:speechmate/screens/explorer_dashboard.dart';
import 'package:speechmate/screens/chat_translate_screen.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';

import 'package:speechmate/screens/dialect_heatmap_screen.dart';
import 'package:speechmate/screens/culture_screen.dart';

// ────────────────────────────────────────────────────────────────────────────
// EXPLORER SHELL — 5-tab bottom navigation
// Home · Translate · Speak (elevated) · Map · Explore
// Uses IndexedStack to preserve state across tab switches.
// ────────────────────────────────────────────────────────────────────────────

class ExplorerShell extends StatefulWidget {
  const ExplorerShell({super.key});

  @override
  State<ExplorerShell> createState() => _ExplorerShellState();
}

class _ExplorerShellState extends State<ExplorerShell> {
  int _currentIndex = 0;

  // Screens — lazily built, state preserved via IndexedStack
  final List<Widget> _screens = const [
    ExplorerDashboard(),
    ChatTranslateScreen(),
    VoiceTranslatorScreen(),
    DialectHeatmapScreen(),
    CultureScreen(),
  ];

  void _onTabTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AndamanPalette.white,
        border: const Border(
          top: BorderSide(color: AndamanPalette.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AndamanPalette.shadowMedium,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.chat_rounded, Icons.chat_outlined, 'Translate'),
              _buildSpeakButton(),
              _buildNavItem(3, Icons.map_rounded, Icons.map_outlined, 'Map'),
              _buildNavItem(4, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AndamanPalette.oceanTealSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? AndamanPalette.oceanTeal : AndamanPalette.mist,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AndamanPalette.oceanTeal : AndamanPalette.mist,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Elevated center button for Voice/Speak — the #1 action
  Widget _buildSpeakButton() {
    final isActive = _currentIndex == 2;
    return GestureDetector(
      onTap: () => _onTabTap(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: isActive ? AndamanPalette.oceanTeal : AndamanPalette.oceanTealSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AndamanPalette.oceanTeal : AndamanPalette.borderTeal,
                width: 2,
              ),
              boxShadow: isActive
                  ? [BoxShadow(color: AndamanPalette.oceanTeal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Icon(
              Icons.mic_rounded,
              color: isActive ? Colors.white : AndamanPalette.oceanTeal,
              size: 24,
            ),
          ),
          Text(
            'Speak',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AndamanPalette.oceanTeal : AndamanPalette.mist,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for tabs not yet implemented (Map, Explore)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndamanPalette.sandWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AndamanPalette.oceanTealSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AndamanPalette.oceanTeal),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: AndamanPalette.stone,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AndamanPalette.mist,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
