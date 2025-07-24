import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SimpleBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color iconColor;
  final double iconSize;
  final Color backgroundColor;

  const SimpleBackAppBar({
    super.key,
    this.iconColor = Colors.white,
    this.iconSize = 28,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leadingWidth: 56, // ← leading 아이콘의 가로 너비 지정
      leading: Padding(
        padding: const EdgeInsets.only(
          left: 16,
        ), // ← 왼쪽 여백 조절 (디자인 기준에 따라 조정 가능)
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor, size: iconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
