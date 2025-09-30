import 'package:flutter/material.dart';
import 'dart:async';
import 'package:LostAtKuet/Login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String displayText = "";
  final String fullText = "Lost @ KUET";
  bool showTagline = false;
  double taglineOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Slower zoom animation (2.5 seconds)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Wait before starting zoom
    await Future.delayed(const Duration(milliseconds: 800));
    _controller.forward();

    // Start typewriter after zoom (~3.3s mark)
    await Future.delayed(const Duration(milliseconds: 2500));
    _startTypewriter();

    // Show tagline after typewriter (~6s mark)
    await Future.delayed(const Duration(milliseconds: 2500));
    _fadeInTagline();

    // Navigate after full duration (~7.5s mark)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _startTypewriter() async {
    for (int i = 0; i <= fullText.length; i++) {
      if (mounted) {
        setState(() {
          displayText = fullText.substring(0, i);
        });
        // Slower typing speed (200ms per character)
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  void _fadeInTagline() {
    setState(() {
      showTagline = true;
    });
    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (mounted) {
        setState(() {
          if (taglineOpacity < 1.0) {
            taglineOpacity += 0.04; // Smooth fade-in
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/lostatkuet_icon.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              displayText,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292929),
              ),
            ),
            const SizedBox(height: 10),
            if (showTagline)
              AnimatedOpacity(
                opacity: taglineOpacity,
                duration: const Duration(milliseconds: 100),
                child: const Text(
                  "Because even small things deserve to be found.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF585858),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
