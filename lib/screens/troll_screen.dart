import 'package:flutter/material.dart';

class TrollScreen extends StatelessWidget {
  const TrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Go Back',
            style: TextStyle(fontSize: 16, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}
