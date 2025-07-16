import 'package:flutter/material.dart';

class InvitingCodeScreen extends StatelessWidget {
  const InvitingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀 코드 입력하기')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('팀 코드 입력'),
            const SizedBox(height: 20),
            TextField(decoration: const InputDecoration(labelText: '코드')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              child: const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
