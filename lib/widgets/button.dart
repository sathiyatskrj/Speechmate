import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/teacher_dash.dart';
import '../screens/student_dash.dart';

class NextButton extends StatelessWidget {
  const NextButton({super.key, required this.selectedRole});

  final String selectedRole;

  Future<void> _onTap(BuildContext context) async {
    // Persist the chosen role so the app auto-navigates next launch
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', selectedRole);

    if (!context.mounted) return;
    if (selectedRole == "teacher") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherDash()));
    } else if (selectedRole == "student") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentDash()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: selectedRole.isEmpty ? null : () => _onTap(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: Colors.black,
        elevation: 3,
      ),
      child: const Text("Next", style: TextStyle(fontSize: 18)),
    );
  }
}
