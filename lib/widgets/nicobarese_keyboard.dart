import 'package:flutter/material.dart';

class NicobareseKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onClose;

  const NicobareseKeyboard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onClose,
  });

  void _insertText(String myText) {
    final text = controller.text;
    final textSelection = controller.selection;
    
    // If no selection, cursor is at end
    if (textSelection.baseOffset == -1) {
       controller.text = text + myText;
       controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
       return;
    }

    final newText = text.replaceRange(
      textSelection.start,
      textSelection.end,
      myText,
    );
    final myTextLength = myText.length;
    controller.text = newText;
    controller.selection = textSelection.copyWith(
      baseOffset: textSelection.start + myTextLength,
      extentOffset: textSelection.start + myTextLength,
    );
  }

  void _backspace() {
    final text = controller.text;
    final textSelection = controller.selection;
    if (textSelection.baseOffset == -1 || text.isEmpty) return;
    
    final selectionLength = textSelection.end - textSelection.start;

    // There is a selection
    if (selectionLength > 0) {
      final newText = text.replaceRange(
        textSelection.start,
        textSelection.end,
        '',
      );
      controller.text = newText;
      controller.selection = textSelection.copyWith(
        baseOffset: textSelection.start,
        extentOffset: textSelection.start,
      );
      return;
    }

    // Cursor is at beginning
    if (textSelection.start == 0) return;

    // Delete character before cursor
    final previousCodeUnit = text.codeUnitAt(textSelection.start - 1);
    final offset = _isUtf16Surrogate(previousCodeUnit) ? 2 : 1;
    final newStart = textSelection.start - offset;
    final newEnd = textSelection.start;
    final newText = text.replaceRange(
      newStart,
      newEnd,
      '',
    );
    controller.text = newText;
    controller.selection = textSelection.copyWith(
      baseOffset: newStart,
      extentOffset: newStart,
    );
  }

  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Padding(
                 padding: EdgeInsets.only(left: 8.0),
                 child: Text("Nicobarese Phonetic", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
               ),
               IconButton(icon: const Icon(Icons.keyboard_hide), onPressed: onClose),
            ]
          ),
          _buildRow(['ö', 'ë', 'ñ', 'ū', 'ō', 'ä', 'ü', 'ī']),
          const SizedBox(height: 5),
          _buildRow(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']),
          const SizedBox(height: 5),
          _buildRow(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l']),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKey('↑', isAction: true, onPressed: () {}), // Shift placeholder
              ...['z', 'x', 'c', 'v', 'b', 'n', 'm'].map((e) => _buildKey(e)),
              _buildKey('⌫', isAction: true, onPressed: _backspace),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKey('?123', isAction: true, onPressed: () {}),
              _buildKey(',', flex: 1),
              _buildKey(' ', flex: 4, onPressed: () => _insertText(' ')),
              _buildKey('.', flex: 1),
              _buildKey('✓', isAction: true, onPressed: onSubmitted, color: Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((e) => _buildKey(e)).toList(),
    );
  }

  Widget _buildKey(String label, {bool isAction = false, VoidCallback? onPressed, int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Material(
          color: color ?? (isAction ? Colors.grey.shade400 : Colors.white),
          borderRadius: BorderRadius.circular(5),
          elevation: 2,
          child: InkWell(
            onTap: onPressed ?? () => _insertText(label),
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 45,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                   fontSize: isAction ? 16 : 20,
                   fontWeight: isAction ? FontWeight.bold : FontWeight.w500,
                   color: color != null ? Colors.white : Colors.black87
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
