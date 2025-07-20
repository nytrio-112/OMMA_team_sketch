import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// 테마 import
import 'theme/theme.dart';

// 화면 import
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/makegroup_screen.dart';
import 'screens/invitingcode_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/diary_detail_screen.dart';
import 'screens/diary_upload_screen.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Diary App',
      debugShowCheckedModeBanner: false,
      theme: appTheme, // ✅ 여기서 전역 테마 적용
      home: const SplashScreen(), // ✅ 로그인 여부 확인용 스플래시
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/signup': (context) => const SignupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/makegroup': (context) => const MakeGroupScreen(),
        '/invitingcode': (context) => const InvitingCodeScreen(),
        '/login': (context) => const LoginScreen(),
        '/mypage': (context) => const MyPageScreen(),
        '/feed': (context) => const FeedScreen(),
        '/diarydetail': (context) => const DiaryDetailScreen(),
        '/diaryupload': (context) => const DiaryUploadScreen(),
      },
    );
  }
}
