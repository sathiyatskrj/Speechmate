import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/league_service.dart';

// ============================================================================
// CLASS LEAGUES SCREEN — Duolingo-style Weekly XP Tournaments
// Bronze → Silver → Gold → Diamond → Legendary
// ============================================================================

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen>
    with SingleTickerProviderStateMixin {
  final LeagueService _leagueService = LeagueService();
  late AnimationController _glowController;
  Timer? _countdownTimer;

  int _currentTier = 0;
  int _weekXP = 0;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadLeagueData();
    _startCountdown();
  }

  Future<void> _loadLeagueData() async {
    final tier = await _leagueService.getCurrentTier();
    final xp = await _leagueService.getWeekXP();
    final members = await _leagueService.getLeagueMembers();

    // Update player XP in members list
    for (final m in members) {
      if (m['isPlayer'] == true) m['weekXP'] = xp;
    }
    members.sort((a, b) => (b['weekXP'] as int).compareTo(a['weekXP'] as int));

    if (mounted) {
      setState(() {
        _currentTier = tier;
        _weekXP = xp;
        _members = members;
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _timeLeft = _leagueService.getTimeUntilReset();
        });
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final tierInfo = LeagueService.getTierInfo(_currentTier);
    final tierColor = Color(tierInfo['color'] as int);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1628),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Weekly League',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1628), Color(0xFF132742), Color(0xFF1B3A5C)],
              ),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          else
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Tier badge with animated glow
                  _buildTierBadge(tierInfo, tierColor),

                  const SizedBox(height: 12),

                  // Countdown timer
                  _buildCountdown(),

                  const SizedBox(height: 16),

                  // League standings
                  Expanded(child: _buildStandings(tierColor)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(Map<String, dynamic> tierInfo, Color tierColor) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (ctx, _) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: tierColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: tierColor.withValues(alpha: 0.3 + 0.3 * _glowController.value),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: tierColor.withValues(alpha: 0.15 * _glowController.value),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(tierInfo['emoji'] as String, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              '${tierInfo['name']} League',
              style: TextStyle(
                color: tierColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_weekXP XP this week',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildCountdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: Colors.cyanAccent.withValues(alpha: 0.6), size: 16),
          const SizedBox(width: 8),
          Text(
            'Resets in ${_formatDuration(_timeLeft)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildStandings(Color tierColor) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final isPlayer = member['isPlayer'] == true;
        final isPromoZone = index < 3;
        final isDemoZone = index >= _members.length - 3;

        Color zoneColor;
        if (isPromoZone) {
          zoneColor = const Color(0xFF00C853); // Green — promotion
        } else if (isDemoZone) {
          zoneColor = const Color(0xFFFF5252); // Red — demotion
        } else {
          zoneColor = Colors.white.withValues(alpha: 0.1);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isPlayer
                    ? tierColor.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPlayer
                      ? tierColor.withValues(alpha: 0.4)
                      : zoneColor.withValues(alpha: 0.3),
                  width: isPlayer ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 32,
                    child: Text(
                      index < 3 ? ['🥇', '🥈', '🥉'][index] : '#${index + 1}',
                      style: TextStyle(
                        fontSize: index < 3 ? 20 : 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar
                  Text(member['avatar'] ?? '👤', style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),

                  // Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name'] ?? 'Student',
                          style: TextStyle(
                            color: isPlayer ? tierColor : Colors.white,
                            fontSize: 15,
                            fontWeight: isPlayer ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                        if (isPromoZone)
                          Text('⬆ Promotion zone',
                              style: TextStyle(color: const Color(0xFF00C853).withValues(alpha: 0.7), fontSize: 10)),
                        if (isDemoZone)
                          Text('⬇ Demotion zone',
                              style: TextStyle(color: const Color(0xFFFF5252).withValues(alpha: 0.7), fontSize: 10)),
                      ],
                    ),
                  ),

                  // XP
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isPlayer ? tierColor : Colors.cyanAccent).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${member['weekXP']} XP',
                      style: TextStyle(
                        color: isPlayer ? tierColor : Colors.cyanAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.08);
      },
    );
  }
}
