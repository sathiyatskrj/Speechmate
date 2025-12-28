import 'package:flutter/material.dart';
import '../features/gamification/gamification_service.dart';
import 'glass_container.dart';

class GamificationHeader extends StatelessWidget {
  const GamificationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.15,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          // Level Circle using simulated progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: GamificationService.xp / max(GamificationService.nextLevelXp, 1),
                  strokeWidth: 5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  "${GamificationService.currentLevel}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          
          // XP & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GamificationService.getLevelTitle(GamificationService.currentLevel),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 5),
                Text(
                  "${GamificationService.xp} / ${GamificationService.nextLevelXp} XP",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                   color: Colors.orange.withOpacity(0.1),
                   blurRadius: 10,
                   spreadRadius: 2
                )
              ]
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 24),
                const SizedBox(width: 4),
                Text(
                  "${GamificationService.currentStreak}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Helper for max to avoid dart:math import issues in simple widgets if not present
int max(int a, int b) => a > b ? a : b;
