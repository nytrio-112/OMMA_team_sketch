import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('환영합니다')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('OOO님 환영합니다! 함께 이용하고 싶은 사람들을 초대해 주세요.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/makegroup');
              },
              child: const Text('+ 그룹 만들기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/invitingcode');
              },
              child: const Text('초대 코드가 있으신가요? 바로 그룹 가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
