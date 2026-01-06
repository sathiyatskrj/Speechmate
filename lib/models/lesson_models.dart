class Lesson {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final List<LessonSlide> slides;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.slides,
  });
}

class LessonSlide {
  final String englishText;
  final String nicobareseText;
  final String imageAsset;
  final String? audioAsset;
  final String? animationTrigger; // 'jump', 'shake', etc.

  const LessonSlide({
    required this.englishText,
    required this.nicobareseText,
    required this.imageAsset,
    this.audioAsset,
    this.animationTrigger,
  });
}

import 'package:flutter/material.dart';

// Pre-defined static data for the lessons
final List<Lesson> interactiveLessons = [
  Lesson(
    id: 'lesson_animals',
    title: 'Jungle Adventure',
    description: 'Learn about animals of Nicobar!',
    icon: '🦁',
    color: Colors.orange,
    slides: [
      LessonSlide(
        englishText: 'Goat',
        nicobareseText: 'Bak-errah',
        imageAsset: 'assets/images/goat.png', // Placeholder, using emoji in UI if missing
        audioAsset: 'assets/audio/goat.mp3',
        animationTrigger: 'jump',
      ),
      LessonSlide(
        englishText: 'Lizard',
        nicobareseText: 'Michāka',
        imageAsset: 'assets/images/lizard.png', 
        audioAsset: 'assets/audio/lizard.mp3',
        animationTrigger: 'shake',
      ),
      LessonSlide(
        englishText: 'Monkey',
        nicobareseText: 'Oin\'che',
        imageAsset: 'assets/images/monkey.png',
        audioAsset: 'assets/audio/monkey.mp3',
        animationTrigger: 'spin',
      ),
    ],
  ),
  Lesson(
    id: 'lesson_nature',
    title: 'Island Colors',
    description: 'The beautiful colors of our island.',
    icon: '🏝️',
    color: Colors.teal,
    slides: [
       LessonSlide(
        englishText: 'Tree',
        nicobareseText: 'Chōn',
        imageAsset: 'assets/images/tree.png',
        animationTrigger: 'grow',
      ),
      LessonSlide(
        englishText: 'Sea',
        nicobareseText: 'Mai',
        imageAsset: 'assets/images/sea.png',
        animationTrigger: 'wave',
      ),
    ],
  ),
];
