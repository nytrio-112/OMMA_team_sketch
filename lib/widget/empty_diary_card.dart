import 'package:flutter/material.dart';
import 'package:my_first_app/constants/colors.dart'; // OmmaColors 쓸 때

class EmptyDiaryCard extends StatelessWidget {
  final VoidCallback onAddPressed;

  const EmptyDiaryCard({super.key, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        height: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '아직 작성된 그림일기가 없어요.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('그림일기 작성하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: OmmaColors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
