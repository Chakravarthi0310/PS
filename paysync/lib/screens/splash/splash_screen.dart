import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/screens/auth/user_details_screen.dart';
import 'package:paysync/screens/main_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:paysync/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 3));

    if (!mounted) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDetails = await DatabaseHelper().getUser(currentUser.uid);

      if (userDetails != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => UserDetailsScreen(
                  userId: currentUser.uid,
                  email: currentUser.email,
                  isGoogleSignIn: currentUser.providerData.any(
                    (element) => element.providerId == 'google.com',
                  ),
                ),
          ),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _opacityAnimation,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    WavyAnimatedText(
                      'PaySync',
                      speed: Duration(milliseconds: 200),
                    ),
                  ],
                  isRepeatingAnimation: false,
                ),
              ),
            ),
            SizedBox(height: 30),
            FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
