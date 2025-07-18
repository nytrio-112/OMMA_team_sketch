import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일

// 기존 화면 import 유지
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Diary App',
      theme: ThemeData(primarySwatch: Colors.purple),
      initialRoute: '/',
      routes: {
        '/': (context) => const IntroScreen(),
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
