import 'package:flutter/material.dart';
import 'package:my_first_app/constants/colors.dart'; // OmmaColors 쓸 때

class DiaryPageIndicator extends StatelessWidget {
  final int count;
  final int current;

  const DiaryPageIndicator({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: current == index ? OmmaColors.green : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}
