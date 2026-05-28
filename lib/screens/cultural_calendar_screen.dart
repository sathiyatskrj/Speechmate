import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

/// M3-04: Cultural calendar showing Nicobarese festivals and events.
/// Persisted locally in SharedPreferences. Teachers can perform CRUD when isTeacher is true.
class CulturalCalendarScreen extends StatefulWidget {
  final bool isTeacher;
  const CulturalCalendarScreen({super.key, this.isTeacher = false});

  @override
  State<CulturalCalendarScreen> createState() => _CulturalCalendarScreenState();
}

class _CulturalCalendarScreenState extends State<CulturalCalendarScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  static final List<Map<String, dynamic>> _defaultEvents = [
    {'month': 'January', 'name': 'Tuh-Naayi', 'desc': 'New Year pig feast — communities share pork and toddy to welcome the year.', 'emoji': '🐖', 'color': 0xFFE91E63},
    {'month': 'February', 'name': 'Canoe Race Festival', 'desc': 'Inter-village outrigger races celebrating seafaring traditions.', 'emoji': '🛶', 'color': 0xFF2196F3},
    {'month': 'April', 'name': 'Ossuary Feast', 'desc': 'Memorial gathering honoring ancestors with songs and offerings.', 'emoji': '🕯️', 'color': 0xFF9C27B0},
    {'month': 'June', 'name': 'Monsoon Prep', 'desc': 'Collective hut-strengthening and pandanus harvesting before rains.', 'emoji': '🌧️', 'color': 0xFF00BCD4},
    {'month': 'August', 'name': 'Coconut Festival', 'desc': 'First coconut harvest celebration — toddy is made and shared.', 'emoji': '🥥', 'color': 0xFF4CAF50},
    {'month': 'October', 'name': 'Fishing Festival', 'desc': 'Communal deep-sea fishing expedition followed by village feast.', 'emoji': '🐟', 'color': 0xFFFF9800},
    {'month': 'December', 'name': 'Winter Gathering', 'desc': 'Story-telling nights where elders share oral histories with children.', 'emoji': '🌙', 'color': 0xFF3F51B5},
  ];

  static final List<int> _presetColors = [
    0xFFE91E63, // Pink
    0xFF2196F3, // Blue
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFF3F51B5, // Indigo
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('cultural_events');
    if (raw == null) {
      // First run: save defaults
      setState(() {
        _events = List<Map<String, dynamic>>.from(_defaultEvents);
        _isLoading = false;
      });
      await _saveEvents();
    } else {
      try {
        final parsed = jsonDecode(raw) as List;
        setState(() {
          _events = parsed.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(_defaultEvents);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cultural_events', jsonEncode(_events));
  }

  void _showEventDialog({Map<String, dynamic>? existingEvent, int? index}) {
    final nameCtrl = TextEditingController(text: existingEvent?['name'] ?? '');
    final descCtrl = TextEditingController(text: existingEvent?['desc'] ?? '');
    final emojiCtrl = TextEditingController(text: existingEvent?['emoji'] ?? '🎉');
    String selectedMonth = existingEvent?['month'] ?? 'January';
    int selectedColor = existingEvent?['color'] ?? _presetColors.first;

    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            existingEvent == null ? 'Add Cultural Event 🎭' : 'Edit Cultural Event 📝',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event Name', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Canoe Race Festival',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true, fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Month', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedMonth,
                  dropdownColor: const Color(0xFF1E293B),
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: months.map((m) => DropdownMenuItem(
                    value: m, child: Text(m, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedMonth = v!),
                ),
                const SizedBox(height: 14),
                Text('Description', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Describe the cultural significance, feast, or tradition...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true, fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emoji Icon', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: emojiCtrl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                            decoration: InputDecoration(
                              filled: true, fillColor: Colors.white.withOpacity(0.06),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme Color', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _presetColors.map((colorVal) {
                              final isSelected = selectedColor == colorVal;
                              return GestureDetector(
                                onTap: () => setDialogState(() => selectedColor = colorVal),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(colorVal),
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final emoji = emojiCtrl.text.trim();
                if (name.isEmpty || desc.isEmpty || emoji.isEmpty) return;

                setState(() {
                  final newEvent = {
                    'month': selectedMonth,
                    'name': name,
                    'desc': desc,
                    'emoji': emoji,
                    'color': selectedColor,
                  };
                  if (existingEvent != null && index != null) {
                    _events[index] = newEvent;
                  } else {
                    _events.add(newEvent);
                  }
                });
                _saveEvents();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existingEvent == null ? '✅ Event added successfully!' : '✅ Event updated successfully!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              child: Text(existingEvent == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEvent(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event ⚠️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this cultural event from the calendar?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _events.removeAt(index);
              });
              _saveEvents();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ Event deleted from calendar'), backgroundColor: Colors.redAccent),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Cultural Calendar', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      floatingActionButton: widget.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => _showEventDialog(),
              backgroundColor: const Color(0xFF0D9488),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Event', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('No events listed yet', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18)),
                      if (widget.isTeacher) ...[
                        const SizedBox(height: 8),
                        Text('Tap + Add Event to create one.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _events.length,
                  itemBuilder: (context, i) {
                    final e = _events[i];
                    final color = Color(e['color'] as int? ?? 0xFFE91E63);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline dot + line
                          Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                              if (i < _events.length - 1)
                                Container(
                                  width: 2,
                                  height: 90,
                                  color: color.withOpacity(0.2),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: color.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e['emoji'] ?? '🎉', style: const TextStyle(fontSize: 28)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (e['month'] ?? '').toUpperCase(),
                                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                                            ),
                                            Text(
                                              e['name'] ?? '',
                                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (widget.isTeacher) ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                                          onPressed: () => _showEventDialog(existingEvent: e, index: i),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.8), size: 18),
                                          onPressed: () => _confirmDeleteEvent(i),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    e['desc'] ?? '',
                                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).slideX(begin: 0.1);
                  },
                ),
    );
  }
}
