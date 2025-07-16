import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(decoration: const InputDecoration(labelText: '이름')),
            TextField(decoration: const InputDecoration(labelText: '아이디')),
            TextField(decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true),
            TextField(decoration: const InputDecoration(labelText: '비밀번호 확인'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/onboarding');
              },
              child: const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
