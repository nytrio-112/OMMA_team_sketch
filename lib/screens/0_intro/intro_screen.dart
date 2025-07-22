import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/text_style.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmmaColors.pink,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고
              const Text('OMMA', style: OmmaTextStyles.logo),
              const SizedBox(height: 60),

              // 로그인 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  foregroundColor: WidgetStateProperty.all(OmmaColors.green),
                  shadowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return OmmaColors.green;
                    }
                    return Colors.transparent;
                  }),
                  elevation: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return 5.0;
                    }
                    return 0.0;
                  }),
                  minimumSize: WidgetStateProperty.all(const Size(250, 60)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'OmmaBodyFont',
                    ),
                  ),
                ),
                child: const Text('로그인'),
              ),

              const SizedBox(height: 20), // 버튼 간 간격
              // 회원가입 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  foregroundColor: WidgetStateProperty.all(OmmaColors.green),
                  shadowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return OmmaColors.green;
                    }
                    return Colors.transparent;
                  }),
                  elevation: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return 5.0;
                    }
                    return 0.0;
                  }),
                  minimumSize: WidgetStateProperty.all(const Size(250, 60)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'OmmaBodyFont',
                    ),
                  ),
                ),
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
