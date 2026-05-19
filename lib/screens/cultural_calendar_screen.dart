import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// M3-04: Cultural calendar showing Nicobarese festivals and events.
class CulturalCalendarScreen extends StatelessWidget {
  const CulturalCalendarScreen({super.key});

  static final List<Map<String, dynamic>> _events = [
    {'month': 'January', 'name': 'Tuh-Naayi', 'desc': 'New Year pig feast — communities share pork and toddy to welcome the year.', 'emoji': '🐖', 'color': 0xFFE91E63},
    {'month': 'February', 'name': 'Canoe Race Festival', 'desc': 'Inter-village outrigger races celebrating seafaring traditions.', 'emoji': '🛶', 'color': 0xFF2196F3},
    {'month': 'April', 'name': 'Ossuary Feast', 'desc': 'Memorial gathering honoring ancestors with songs and offerings.', 'emoji': '🕯️', 'color': 0xFF9C27B0},
    {'month': 'June', 'name': 'Monsoon Prep', 'desc': 'Collective hut-strengthening and pandanus harvesting before rains.', 'emoji': '🌧️', 'color': 0xFF00BCD4},
    {'month': 'August', 'name': 'Coconut Festival', 'desc': 'First coconut harvest celebration — toddy is made and shared.', 'emoji': '🥥', 'color': 0xFF4CAF50},
    {'month': 'October', 'name': 'Fishing Festival', 'desc': 'Communal deep-sea fishing expedition followed by village feast.', 'emoji': '🐟', 'color': 0xFFFF9800},
    {'month': 'December', 'name': 'Winter Gathering', 'desc': 'Story-telling nights where elders share oral histories with children.', 'emoji': '🌙', 'color': 0xFF3F51B5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white,
        title: const Text('Cultural Calendar', style: TextStyle(fontWeight: FontWeight.w800)), centerTitle: true),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _events.length,
        itemBuilder: (context, i) {
          final e = _events[i];
          final color = Color(e['color'] as int);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot + line
                Column(children: [
                  Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: color,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)])),
                  if (i < _events.length - 1) Container(width: 2, height: 80, color: color.withValues(alpha: 0.2)),
                ]),
                const SizedBox(width: 16),
                // Card
                Expanded(child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(e['emoji'] ?? '', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e['month'] ?? '', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        Text(e['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      ])),
                    ]),
                    const SizedBox(height: 8),
                    Text(e['desc'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.5)),
                  ]),
                )),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).slideX(begin: 0.1);
        },
      ),
    );
  }
}
