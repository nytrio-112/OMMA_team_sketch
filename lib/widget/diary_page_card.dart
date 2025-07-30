import 'package:flutter/material.dart';
import 'package:my_first_app/constants/colors.dart';

class DiaryPageCard extends StatelessWidget {
  final Map<String, dynamic> diaryData;
  final bool isMyDiary;
  final VoidCallback? onToggleRevealed;
  final VoidCallback? onImageTap;

  DiaryPageCard({
    super.key,
    required this.diaryData,
    required this.isMyDiary,
    this.onToggleRevealed,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (diaryData['imageUrl'] as String?)?.trim();
    final title = diaryData['title'] ?? '';
    final content = diaryData['content'] ?? '';
    final isRevealed = diaryData['isRevealed'] ?? false;
    final createdByNickname = diaryData['createdByNickname'] ?? '익명';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRevealed && createdByNickname.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    createdByNickname,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // 이미지
            if (imageUrl != null)
              GestureDetector(
                onTap: onImageTap,
                child: Image.network(
                  imageUrl,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error, size: 100, color: Colors.red),
                    );
                  },
                ),
              )
            else
              const Icon(Icons.image, size: 200, color: Colors.grey),

            const SizedBox(height: 12),

            // 제목/내용
            if (isRevealed) ...[
              Text("제목: $title", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(content, style: const TextStyle(fontSize: 14)),
            ] else
              const Text(
                '(작성자가 아직 제목과 내용을 공개하지 않았어요)',
                style: TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 12),

            // 공개 토글 (작성자만)
            if (isMyDiary && onToggleRevealed != null)
              ElevatedButton(
                onPressed: onToggleRevealed!,
                child: Text(isRevealed ? '숨기기' : '일기 공개'),
              ),
          ],
        ),
      ),
    );
  }
}
