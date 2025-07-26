import 'package:flutter/material.dart';
import 'package:my_first_app/constants/colors.dart'; // OmmaColors 쓸 때

class DiaryPageCard extends StatelessWidget {
  final Map<String, dynamic> diaryData;
  final bool isLastPage;
  final bool isMyDiary;
  final VoidCallback? onAddPressed;

  const DiaryPageCard({
    super.key,
    required this.diaryData,
    required this.isLastPage,
    required this.isMyDiary,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = diaryData['imageUrl'] ?? '';
    print('📸 로딩할 이미지 URL: $imageUrl');

    final title = diaryData['title'] ?? '';
    final isRevealed = diaryData['isRevealed'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          if (imageUrl != '')
            Image.network(
              imageUrl, // ✅ 디코딩 없이 그대로 사용
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('🧨 이미지 로딩 실패: $error');
                print('🧵 StackTrace: $stackTrace');
                return const Text('(이미지를 불러올 수 없습니다)');
              },
            )
          else
            const Icon(Icons.image, size: 200, color: Colors.grey),

          const SizedBox(height: 12),
          Text(
            isRevealed ? title : '(작성자가 아직 내용을 공개하지 않았어요)',
            style: const TextStyle(fontSize: 16),
          ),

          // 마지막 페이지 + 작성자만 아니라면 → + 버튼
          if (isLastPage && !isMyDiary && onAddPressed != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add),
                label: const Text('그림일기 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OmmaColors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
