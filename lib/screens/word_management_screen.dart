import 'package:flutter/material.dart';
import '../widgets/background.dart';

class WordManagementScreen extends StatelessWidget {
  const WordManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Manage Dictionary", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Background(
         // Basic gradient background usage if constructor differs, check Background widget definition? 
         // Assuming Background accepts child.
        child: const Center(
          child: Text(
            "Word Management Feature\n(Coming Soon)", 
            textAlign: TextAlign.center, 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
