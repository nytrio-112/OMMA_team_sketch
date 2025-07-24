import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: const Color(0xFFE0F3EC), // 연한 민트색 (디자인 참고)
      selectedItemColor: OmmaColors.green,
      unselectedItemColor: Colors.grey,
      elevation: 8,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/mypage',
            (route) => false,
          );
        }
        // 다른 버튼 생기면 여기에 추가
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person), // 또는 다른 아무 아이콘
          label: '프로필',
        ),
      ],
    );
  }
}
