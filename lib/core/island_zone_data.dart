import 'package:flutter/material.dart';
import 'package:speechmate/screens/games/games_hub_screen.dart';
import 'package:speechmate/screens/voice_vault_screen.dart';
import 'package:speechmate/screens/dynamic_category_screen.dart';
import 'package:speechmate/screens/feedback_screen.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/flora_fauna_screen.dart';
import 'package:speechmate/screens/omni_translator_screen.dart';
import 'package:speechmate/screens/story_radio_screen.dart';
import 'package:speechmate/screens/kinship_mapper_screen.dart';
import 'package:speechmate/screens/dialect_heatmap_screen.dart';
import 'package:speechmate/screens/memory_palace_screen.dart';
import 'package:speechmate/screens/camera_translation_screen.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';
import 'package:speechmate/screens/ar_translator_screen.dart';
import 'package:speechmate/screens/body_parts_screen.dart';
import 'package:speechmate/screens/ai_setup_screen.dart';
import 'package:speechmate/screens/regional_translator_screen.dart';
import 'package:speechmate/screens/classroom_leaderboard_screen.dart';
import 'package:speechmate/screens/achievement_badges_screen.dart';
import 'package:speechmate/screens/cultural_calendar_screen.dart';
import 'package:speechmate/screens/sos_phrases_screen.dart';
import 'package:speechmate/screens/league_screen.dart';
import 'package:speechmate/screens/phrasebook_screen.dart';
import 'package:speechmate/screens/pronunciation_challenge_screen.dart';
import 'package:speechmate/screens/conversation_mode_screen.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// ============================================================================
// ISLAND ZONE DATA MODEL — Student Dashboard Navigation Architecture
// ============================================================================
// Defines the 5 island zones that categorize all student features.
// Zone 0 (Home Beach) is special — it renders stats/mission widgets, not tiles.
// Zones 1-4 render feature tile grids.
// ============================================================================

class IslandZone {
  final String name;
  final String emoji;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final List<Map<String, dynamic>> tiles;

  const IslandZone({
    required this.name,
    required this.emoji,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.tiles,
  });
}

/// Returns the 5 island zones with all feature tiles assigned.
/// Zone 0 tiles are empty because Home Beach renders custom widgets.
List<IslandZone> getIslandZones() {
  return [
    // ── Zone 0: Home Beach (custom widgets, no tile grid) ──
    IslandZone(
      name: 'Home Beach',
      emoji: '🏖️',
      description: 'Your daily progress & pet companion',
      icon: Icons.home_rounded,
      gradientColors: [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
      tiles: [], // Rendered by custom widget builders
    ),

    // ── Zone 1: Learning Lagoon (Core Categories) ──
    IslandZone(
      name: 'Learning Lagoon',
      emoji: '🌊',
      description: 'Master words in every category',
      icon: Icons.auto_stories_rounded,
      gradientColors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
      tiles: [
        {
          "word": AppStrings.get('numbers'),
          "emoji": "123",
          "colors": [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
          "navigateTo": const DynamicCategoryScreen(categoryId: 'numbers', title: 'Numbers'),
          "icon": Icons.format_list_numbered_rounded
        },
        {
          "word": AppStrings.get('nature'),
          "emoji": "🌱",
          "colors": [const Color(0xFF11998E), const Color(0xFF38EF7D)],
          "navigateTo": const DynamicCategoryScreen(categoryId: 'nature', title: 'Nature'),
          "icon": Icons.eco_rounded
        },
        {
          "word": AppStrings.get('feelings'),
          "emoji": "🎭",
          "colors": [const Color(0xFFFF512F), const Color(0xFFDD2476)],
          "navigateTo": const DynamicCategoryScreen(categoryId: 'feelings', title: 'Feelings'),
          "icon": Icons.emoji_emotions_rounded
        },
        {
          "word": AppStrings.get('colors'),
          "emoji": "🎨",
          "colors": [const Color(0xFFff9a9e), const Color(0xFFfad0c4)],
          "navigateTo": const DynamicCategoryScreen(categoryId: 'colors', title: 'Colors'),
          "icon": Icons.palette_rounded
        },
        {
          "word": AppStrings.get('things'),
          "emoji": "🏡",
          "colors": [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
          "navigateTo": const DynamicCategoryScreen(categoryId: 'things', title: 'Things'),
          "icon": Icons.chair_rounded
        },
        {
          "word": AppStrings.get('bodyParts'),
          "emoji": "🦴",
          "colors": [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
          "navigateTo": const BodyPartsScreen(),
          "icon": Icons.accessibility_new_rounded
        },
        {
          "word": AppStrings.get('animals'),
          "emoji": "🐶",
          "colors": [const Color(0xFFFF8008), const Color(0xFFFFC837)],
          "navigateTo": const DynamicCategoryScreen(categoryId: 'animals', title: 'Animals'),
          "icon": Icons.pets_rounded
        },
        {
          "word": AppStrings.get('magicWords'),
          "emoji": "🔮",
          "colors": [const Color(0xFFCC2B5E), const Color(0xFF753A88)],
          "navigateTo": const DynamicCategoryScreen(categoryId: 'magic', title: 'Magic Words'),
          "icon": Icons.auto_fix_high_rounded
        },
        {
          "word": AppStrings.get('family'),
          "emoji": "👨‍👩‍👧",
          "colors": [const Color(0xFF2193B0), const Color(0xFF6DD5ED)],
          "navigateTo": const DynamicCategoryScreen(categoryId: 'family', title: 'Family'),
          "icon": Icons.family_restroom_rounded
        },
      ],
    ),

    // ── Zone 2: Adventure Cove (Interactive/Games) ──
    IslandZone(
      name: 'Adventure Cove',
      emoji: '🎮',
      description: 'Play games & explore with cameras',
      icon: Icons.sports_esports_rounded,
      gradientColors: [const Color(0xFFF09819), const Color(0xFFEDDE5D)],
      tiles: [
        {
          "word": AppStrings.get('games'),
          "emoji": "🎲",
          "colors": [const Color(0xFFF09819), const Color(0xFFEDDE5D)],
          "navigateTo": const GamesHubScreen(),
          "icon": Icons.sports_esports_rounded
        },
        {
          "word": AppStrings.get('arTranslator'),
          "emoji": "📷",
          "colors": [const Color(0xFF0F2027), const Color(0xFF2C5364)],
          "navigateTo": const ARTranslatorScreen(),
          "icon": Icons.view_in_ar_rounded
        },
        {
          "word": AppStrings.get('bookScanner'),
          "emoji": "📖",
          "colors": [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
          "navigateTo": const CameraTranslationScreen(),
          "icon": Icons.document_scanner_rounded
        },
        {
          "word": 'Pronunciation Practice',
          "emoji": "🎤",
          "colors": [const Color(0xFF00FF87), const Color(0xFF60EFFF)],
          "navigateTo": const PronunciationChallengeScreen(),
          "icon": Icons.mic_external_on_rounded
        },
        {
          "word": 'Conversation Mode',
          "emoji": "🗣️",
          "colors": [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
          "navigateTo": const ConversationModeScreen(),
          "icon": Icons.forum_rounded
        },
        {
          "word": AppStrings.get('memoryPalace'),
          "emoji": "🏠",
          "colors": [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          "navigateTo": const MemoryPalaceScreen(),
          "icon": Icons.map_rounded,
        },
      ],
    ),

    // ── Zone 3: Translation Reef (Translators & Phrases) ──
    IslandZone(
      name: 'Translation Reef',
      emoji: '🌐',
      description: 'Translate between languages',
      icon: Icons.translate_rounded,
      gradientColors: [const Color(0xFFff0844), const Color(0xFFffb199)],
      tiles: [
        {
          "word": AppStrings.get('voiceTranslate'),
          "emoji": "🎙️",
          "colors": [const Color(0xFFff0844), const Color(0xFFffb199)],
          "navigateTo": const VoiceTranslatorScreen(),
          "icon": Icons.record_voice_over_rounded
        },
        {
          "word": AppStrings.get('chatTranslate'),
          "emoji": "💬",
          "colors": [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
          "navigateTo": const BetaChatScreen(isStudent: true),
          "icon": Icons.chat_bubble_rounded,
        },
        {
          "word": AppStrings.get('omniBroadcast'),
          "emoji": "📡",
          "colors": [const Color(0xFF1A2980), const Color(0xFF26D0CE)],
          "navigateTo": const OmniTranslatorScreen(),
          "icon": Icons.cell_tower_rounded
        },
        {
          "word": AppStrings.get('hindiTranslator'),
          "emoji": "🇮🇳",
          "colors": [const Color(0xFFD84315), const Color(0xFFFF7042)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig('Hindi', TranslateLanguage.hindi, 'hi', 'hi-IN', 'नमस्ते')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": AppStrings.get('tamilTranslator'),
          "emoji": "🛕",
          "colors": [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig('Tamil', TranslateLanguage.tamil, 'ta', 'ta-IN', 'வணக்கம்')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": AppStrings.get('bengaliTranslator'),
          "emoji": "🐅",
          "colors": [const Color(0xFFC62828), const Color(0xFFEF5350)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig('Bengali', TranslateLanguage.bengali, 'bn', 'bn-IN', 'নমস্কার')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": AppStrings.get('teluguTranslator'),
          "emoji": "🌶️",
          "colors": [const Color(0xFF283593), const Color(0xFF5C6BC0)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig('Telugu', TranslateLanguage.telugu, 'te', 'te-IN', 'నమస్కారం')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": AppStrings.get('malayalamTranslator'),
          "emoji": "🥥",
          "colors": [const Color(0xFF00695C), const Color(0xFF26A69A)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig('Malayalam', null, 'ml', 'ml-IN', 'നമസ്കാരം')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": 'Situational Phrasebook',
          "emoji": "🧳",
          "colors": [const Color(0xFF2E8B57), const Color(0xFF3CB371)],
          "navigateTo": const PhrasebookScreen(),
          "icon": Icons.wallet_travel_rounded
        },
        {
          "word": 'Emergency SOS Phrases',
          "emoji": "⛑️",
          "colors": [const Color(0xFFE52D27), const Color(0xFFB31217)],
          "navigateTo": const SOSPhrasesScreen(),
          "icon": Icons.emergency_rounded
        },
      ],
    ),

    // ── Zone 4: Discovery Island (Exploration & Culture) ──
    IslandZone(
      name: 'Discovery Island',
      emoji: '🧭',
      description: 'Explore culture, compete & discover',
      icon: Icons.explore_rounded,
      gradientColors: [const Color(0xFF4A148C), const Color(0xFF1A237E)],
      tiles: [
        {
          "word": 'Leaderboard',
          "emoji": "🏆",
          "colors": [const Color(0xFFDAA520), const Color(0xFFFF8C00)],
          "navigateTo": const LeagueScreen(),
          "icon": Icons.leaderboard_rounded
        },
        {
          "word": 'Achievements',
          "emoji": "🏅",
          "colors": [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
          "navigateTo": const AchievementBadgesScreen(),
          "icon": Icons.emoji_events_rounded
        },
        {
          "word": 'Cultural Calendar',
          "emoji": "🎭",
          "colors": [const Color(0xFFEC4899), const Color(0xFFF472B6)],
          "navigateTo": const CulturalCalendarScreen(),
          "icon": Icons.calendar_month_rounded
        },
        {
          "word": AppStrings.get('voiceVault'),
          "emoji": "🎙️",
          "colors": [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)],
          "navigateTo": const VoiceVaultScreen(),
          "icon": Icons.mic_external_on_rounded,
        },
        {
          "word": AppStrings.get('andamaneseBeta'),
          "emoji": "🏝️",
          "colors": [const Color(0xFF4A148C), const Color(0xFF1A237E)],
          "navigateTo": const GAHubScreen(),
          "icon": Icons.language_rounded
        },
        {
          "word": AppStrings.get('natureHub'),
          "emoji": "🌿",
          "colors": [const Color(0xFF1B5E20), const Color(0xFF004D40)],
          "navigateTo": const FloraFaunaScreen(),
          "icon": Icons.eco_rounded
        },
        {
          "word": AppStrings.get('oralHistory'),
          "emoji": "📻",
          "colors": [const Color(0xFF3E2723), const Color(0xFF1B5E20)],
          "navigateTo": const StoryRadioScreen(),
          "icon": Icons.radio_rounded
        },
        {
          "word": AppStrings.get('tuhetKinship'),
          "emoji": "🌳",
          "colors": [const Color(0xFF5D4037), const Color(0xFF3E2723)],
          "navigateTo": const KinshipMapperScreen(),
          "icon": Icons.account_tree_rounded
        },
        {
          "word": AppStrings.get('islandExplorer'),
          "emoji": "🧭",
          "colors": [const Color(0xFF0277BD), const Color(0xFF01579B)],
          "navigateTo": const DialectHeatmapScreen(),
          "icon": Icons.explore_rounded,
        },
        {
          "word": AppStrings.get('community'),
          "emoji": "🌍",
          "colors": [const Color(0xFF302B63), const Color(0xFF24243E)],
          "navigateTo": const CommunityScreen(),
          "isSecret": true,
          "icon": Icons.public_rounded,
        },
        {
          "word": AppStrings.get('aiSetup'),
          "emoji": "🧠",
          "colors": [const Color(0xFF3b8d99), const Color(0xFF6b6b83)],
          "navigateTo": const AISetupScreen(),
          "icon": Icons.psychology_rounded,
        },
        {
          "word": AppStrings.get('feedback'),
          "emoji": "⭐",
          "colors": [const Color(0xFFFF00CC), const Color(0xFF333399)],
          "navigateTo": const FeedbackScreen(),
          "icon": Icons.feedback_rounded
        },
      ],
    ),
  ];
}
