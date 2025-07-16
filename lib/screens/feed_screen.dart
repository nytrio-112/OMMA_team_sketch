import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('채팅방 이름')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '2025-07-01 화요일\nQ. 오늘 본 것 중에 가장 인상 깊었던 것은?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 🖼️ 그림 클릭 시 상세 페이지 이동
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/diarydetail'); // 상세화면으로 이동
            },
            child: Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Text('그림 일기 (터치하면 상세화면)')),
            ),
          ),

          const SizedBox(height: 12),
          const Text('댓글'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('닉네임1'),
            subtitle: const Text('댓글 내용입니다'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('닉네임2'),
            subtitle: const Text('댓글 내용입니다'),
          ),
        ],
      ),

      // ➕ 업로드 버튼 (화면 오른쪽 하단 floating)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/diaryupload'); // 업로드 화면으로 이동
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

