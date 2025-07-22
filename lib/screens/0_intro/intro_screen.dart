import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('회원가입'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                 Navigator.pushNamed(context, '/login');
              },
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
