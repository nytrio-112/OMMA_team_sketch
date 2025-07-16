import 'package:flutter/material.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('OOO님의 OMMA', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('채팅방 이름 1'),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () {
                      Navigator.pushNamed(context, '/feed');
                    },
                  ),
                  ListTile(
                    title: const Text('채팅방 이름 2'),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () {
                      Navigator.pushNamed(context, '/feed');
                    },
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
