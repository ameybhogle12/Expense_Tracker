import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Play the splash animation for 4 seconds, then transition to AuthWrapper
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212), // Sleek, premium dark background
      body: SizedBox.expand(
        child: Image(
          image: AssetImage('assets/icon/Logo Animation.gif'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
