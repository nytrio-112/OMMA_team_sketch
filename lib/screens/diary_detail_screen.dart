import 'package:flutter/material.dart';

class DiaryDetailScreen extends StatelessWidget {
  const DiaryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('그림일기 상세')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2025년 7월 2일 수요일',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 🖼️ 그림 영역 (터치 가능)
            GestureDetector(
              onTap: () {
                // TODO: 여기서 그림 확대 뷰로 이동 가능 (미리 대비)
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: Container(
                      color: Colors.grey[200],
                      width: double.infinity,
                      height: 400,
                      child: const Center(child: Text('확대된 그림 이미지')),
                    ),
                  ),
                );
              },
              child: Container(
                color: Colors.grey[200],
                width: double.infinity,
                height: 300,
                child: const Center(child: Text('그림 이미지 영역\n(터치하면 확대)')),
              ),
            ),

            const SizedBox(height: 16),
            const Text('제목: 재밌기를 만났던 하루',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text(
              '아이랑 재밌게 놀며 오늘의 일들을 되돌아보고 이야기했어요.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

