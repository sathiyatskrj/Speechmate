import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum KeyboardTheme {
  forestTeal,
  tribalCoral,
  midnightSovereign,
  coconutShell,
}

class NicobareseInAppKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onClose;
  final KeyboardTheme initialTheme;

  const NicobareseInAppKeyboard({
    super.key,
    required this.controller,
    this.onClose,
    this.initialTheme = KeyboardTheme.forestTeal,
  });

  @override
  State<NicobareseInAppKeyboard> createState() => _NicobareseInAppKeyboardState();
}

class _NicobareseInAppKeyboardState extends State<NicobareseInAppKeyboard> {
  late KeyboardTheme _currentTheme;
  bool _isShiftEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME VISUAL PALETTES
  // ═══════════════════════════════════════════════════════════════════════════

  Color get _backgroundColor {
    switch (_currentTheme) {
      case KeyboardTheme.forestTeal:
        return const Color(0xFF0C1D24);
      case KeyboardTheme.tribalCoral:
        return const Color(0xFF2C1916);
      case KeyboardTheme.midnightSovereign:
        return const Color(0xFF080C14);
      case KeyboardTheme.coconutShell:
        return const Color(0xFF251F1C);
    }
  }

  Color get _keyColor {
    switch (_currentTheme) {
      case KeyboardTheme.forestTeal:
        return const Color(0xFF14303A);
      case KeyboardTheme.tribalCoral:
        return const Color(0xFF4A2B27);
      case KeyboardTheme.midnightSovereign:
        return const Color(0xFF1A2232);
      case KeyboardTheme.coconutShell:
        return const Color(0xFF3A302C);
    }
  }

  Color get _accentColor {
    switch (_currentTheme) {
      case KeyboardTheme.forestTeal:
        return Colors.tealAccent;
      case KeyboardTheme.tribalCoral:
        return Colors.orangeAccent;
      case KeyboardTheme.midnightSovereign:
        return Colors.amberAccent;
      case KeyboardTheme.coconutShell:
        return const Color(0xFFD4A373);
    }
  }

  Color get _textColor {
    return Colors.white;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION KEY HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    final charToInsert = _isShiftEnabled ? key.toUpperCase() : key.toLowerCase();
    
    final newText = text.replaceRange(
      selection.start.clamp(0, text.length),
      selection.end.clamp(0, text.length),
      charToInsert,
    );
    
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: selection.start.clamp(0, text.length) + charToInsert.length,
    );
  }

  void _onBackspace() {
    HapticFeedback.mediumImpact();
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (text.isEmpty || selection.start == 0) return;

    final start = selection.start - 1;
    final end = selection.start;

    final newText = text.replaceRange(start, end, '');
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(offset: start);
  }

  void _onSpace() {
    _onKeyPress(' ');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KEYBOARD LAYOUT GENERATORS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildKey(String label, {double flex = 1.0, VoidCallback? onTap}) {
    return Expanded(
      flex: (flex * 100).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: GestureDetector(
          onTap: onTap ?? () => _onKeyPress(label),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: _keyColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _isShiftEnabled ? label.toUpperCase() : label,
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(Widget child, {double flex = 1.0, required VoidCallback onTap, Color? customColor}) {
    return Expanded(
      flex: (flex * 100).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: customColor ?? _keyColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keyboard toolbar: theme switcher & close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Theme switcher buttons
                Row(
                  children: KeyboardTheme.values.map((t) {
                    final isCurrent = t == _currentTheme;
                    Color indicatorColor;
                    switch (t) {
                      case KeyboardTheme.forestTeal:
                        indicatorColor = Colors.tealAccent;
                        break;
                      case KeyboardTheme.tribalCoral:
                        indicatorColor = Colors.orangeAccent;
                        break;
                      case KeyboardTheme.midnightSovereign:
                        indicatorColor = Colors.amberAccent;
                        break;
                      case KeyboardTheme.coconutShell:
                        indicatorColor = const Color(0xFFD4A373);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentTheme = t);
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: indicatorColor,
                            border: Border.all(
                              color: isCurrent ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Close Keyboard
                IconButton(
                  icon: Icon(Icons.keyboard_hide_rounded, color: _accentColor, size: 24),
                  onPressed: widget.onClose,
                )
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Row 1: Dedicated Sovereign Vowels & Accents
          Row(
            children: [
              _buildKey('ä'),
              _buildKey('ö'),
              _buildKey('ë'),
              _buildKey('ṅ'),
              _buildKey('·'),
            ],
          ),

          // Row 2: Standard QWERTY Top
          Row(
            children: ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']
                .map((l) => _buildKey(l))
                .toList(),
          ),

          // Row 3: Standard QWERTY Middle
          Row(
            children: ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l']
                .map((l) => _buildKey(l))
                .toList(),
          ),

          // Row 4: Shift, Bottom Row, Backspace
          Row(
            children: [
              _buildActionKey(
                Icon(
                  Icons.arrow_upward_rounded,
                  color: _isShiftEnabled ? _accentColor : _textColor.withValues(alpha: 0.5),
                  size: 22,
                ),
                flex: 1.5,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isShiftEnabled = !_isShiftEnabled);
                },
              ),
              ...['z', 'x', 'c', 'v', 'b', 'n', 'm'].map((l) => _buildKey(l)),
              _buildActionKey(
                Icon(Icons.backspace_rounded, color: _textColor, size: 20),
                flex: 1.5,
                onTap: _onBackspace,
              ),
            ],
          ),

          // Row 5: 123, Comma, Space, Dot, Done
          Row(
            children: [
              _buildActionKey(
                Text('123', style: TextStyle(color: _textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
                flex: 1.5,
                onTap: () {},
              ),
              _buildKey(','),
              _buildActionKey(
                Text('Space', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                flex: 4.5,
                onTap: _onSpace,
              ),
              _buildKey('.'),
              _buildActionKey(
                Icon(Icons.keyboard_return_rounded, color: _backgroundColor, size: 24),
                flex: 1.5,
                customColor: _accentColor,
                onTap: widget.onClose ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
