import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// 테마 import
import 'theme/theme.dart';

// 화면 import
import 'screens/splash_screen.dart';

import 'screens/0_intro/intro_screen.dart';
import 'screens/0_intro/login_screen.dart';
import 'screens/0_intro/signup_screen.dart';

import 'screens/1_mypage/mypage_screen.dart';

import 'screens/2_group/makegroup_screen.dart';
import 'screens/2_group/invitingcode_screen.dart';
import 'screens/2_group/onboarding_screen.dart';

import 'screens/3_feed/feed_screen.dart';
import 'screens/3_feed/diary_detail_screen.dart';

import 'screens/4_drawAndUpload/diary_upload_screen.dart';

// ✅ 로그 로거 import
import 'analytics/usage_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _startedVisit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 처음 활성화될 때 visit 시작
    if (!_startedVisit && state == AppLifecycleState.resumed) {
      UsageLogger.instance.startVisit("app_entry");
      _startedVisit = true;
    }

    // 앱이 완전히 종료될 때 visit 종료
    if (state == AppLifecycleState.detached) {
      UsageLogger.instance.endVisit(reason: "background");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Diary App',
      debugShowCheckedModeBanner: false,
      theme: appTheme, // ✅ 전역 테마
      navigatorObservers: [
        UsageLogger.instance,
      ], // ✅ RouteObserver 연결 (화면 이동 자동 추적)
      home: const SplashScreen(), // ✅ 로그인 여부 확인용 스플래시
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/signup': (context) => const SignupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/makegroup': (context) => const MakeGroupScreen(),
        '/invitingcode': (context) => const InvitingCodeScreen(),
        '/login': (context) => const LoginScreen(),
        '/myhome': (context) => const MyPageScreen(),
        '/mypage': (context) => const MyPageScreen(),
        '/feed': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return FeedScreen(
            groupId: args['groupId'],
            groupName: args['groupName'],
            currentUserId: args['currentUserId'],
          );
        },
        '/diary_detail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return DiaryDetailScreen(
            imageUrl: args['imageUrl'],
            title: args['title'],
            content: args['content'],
            dateText: args['dateText'],
          );
        },
        '/diary_upload': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return const DiaryUploadScreen(); // groupId/date는 내부에서 args 처리
        },
      },
    );
  }
}
