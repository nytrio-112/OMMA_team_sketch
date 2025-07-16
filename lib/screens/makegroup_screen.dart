import 'package:flutter/material.dart';

class MakeGroupScreen extends StatelessWidget {
  const MakeGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('그룹 만들기')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(value: '가족', child: Text('가족')),
                DropdownMenuItem(value: '친구', child: Text('친구')),
              ],
              onChanged: (value) {},
              decoration: const InputDecoration(labelText: '우리의 관계'),
            ),
            TextField(decoration: const InputDecoration(labelText: '관계 속 나는')),
            TextField(decoration: const InputDecoration(labelText: '성별')),
            TextField(decoration: const InputDecoration(labelText: '나이')),
            TextField(decoration: const InputDecoration(labelText: '닉네임')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/invitingcode');
              },
              child: const Text('완료'),
            ),
          ],
        ),
      ),
    );
  }
}
