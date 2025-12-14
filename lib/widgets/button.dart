import 'package:flutter/material.dart';
import '../screens/teacher_dash.dart';
import '../screens/student_dash.dart';
import 'tap_scale.dart';

class NextButton extends StatelessWidget {
  const NextButton({
    super.key,
    required this.selectedRole,
  });

  final String selectedRole;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: selectedRole.isEmpty ? null : () {
        if (selectedRole == "teacher") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeacherDash()),
          );
        } else if (selectedRole == "student") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentDash()),
          );
        }
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
        padding:
        const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        foregroundColor: Colors.black,
        elevation: 3,
      ),
      child: const Text(
        "Next",
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}