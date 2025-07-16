import 'package:flutter/material.dart';

class DiaryUploadScreen extends StatefulWidget {
  const DiaryUploadScreen({super.key});

  @override
  State<DiaryUploadScreen> createState() => _DiaryUploadScreenState();
}

class _DiaryUploadScreenState extends State<DiaryUploadScreen> {
  Color selectedColor = Colors.blue; // 기본 색상
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('그림일기 업로드')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('2025년 7월 2일 수요일', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),

            // 🖼️ 그림 업로드 영역
            GestureDetector(
              onTap: () {
                // TODO: 갤러리에서 이미지 선택하는 로직 추가 예정
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('그림 업로드 기능은 준비 중입니다')),
                );
              },
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: selectedColor.withOpacity(0.3),
                  border: Border.all(color: selectedColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('터치해서 그림 업로드')),
              ),
            ),
            const SizedBox(height: 16),

            // 🎨 색상 선택
            Row(
              children: [
                const Text('색상 선택: '),
                ...Colors.primaries.map((color) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 12,
                          child: selectedColor == color
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 16),

            // 📝 제목 입력
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 📝 내용 입력
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),

            // ✅ 업로드 버튼
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 업로드 처리 로직
                print('제목: ${titleController.text}');
                print('내용: ${contentController.text}');
                print('선택된 색상: $selectedColor');
                Navigator.pop(context);
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('업로드'),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
