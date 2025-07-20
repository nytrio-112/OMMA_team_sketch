import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'intro_screen.dart';
import 'mypage_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first, // ✅ 이게 핵심
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MyPageScreen(); // ✅ 로그인 상태
        } else {
          return const IntroScreen(); // ❌ 로그인 안 된 상태
        }
      },
    );
  }
}
