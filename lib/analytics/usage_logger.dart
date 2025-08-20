// lib/analytics/usage_logger.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 앱 전역에서 사용하는 UsageLogger
/// - RouteObserver 로 화면 전환 감지
/// - WidgetsBindingObserver 로 앱 라이프사이클 감지
class UsageLogger extends RouteObserver<PageRoute<dynamic>>
    with WidgetsBindingObserver {
  static final UsageLogger instance = UsageLogger._internal();
  UsageLogger._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _visitId;
  String? _userId;
  int _pageSeq = 0;
  String? _currentPageId;
  DateTime? _pageStart;

  /// Visit 시작 (앱 진입 시 1회)
  Future<void> startVisit(String entryScreen) async {
    final user = _auth.currentUser;
    if (user == null) return;
    _userId = user.uid;
    _visitId = _firestore.collection('tmp').doc().id; // 랜덤 ID 생성
    _pageSeq = 0;

    await _firestore
        .collection('usage_visits')
        .doc(_userId)
        .collection('visits')
        .doc(_visitId)
        .set({
          'startedAt': FieldValue.serverTimestamp(),
          'entryScreen': entryScreen,
          'device': 'flutter', // TODO: platform 구분 로직 추가
          'appVersion': '1.0.0', // TODO: 버전 가져오기
          'pagesCount': 0,
        });
  }

  /// Visit 종료
  Future<void> endVisit({String reason = 'normal', String? exitScreen}) async {
    if (_userId == null || _visitId == null) return;
    await _endPage();

    final ref = _firestore
        .collection('usage_visits')
        .doc(_userId)
        .collection('visits')
        .doc(_visitId);

    await ref.update({
      'endedAt': FieldValue.serverTimestamp(),
      'endedReason': reason,
      'exitScreen': exitScreen,
    });

    _visitId = null;
    _userId = null;
  }

  /// Page 시작
  Future<void> _startPage(String screen) async {
    if (_userId == null || _visitId == null) return;
    await _endPage(); // 기존 페이지 마감

    _currentPageId = _firestore.collection('tmp').doc().id;
    _pageStart = DateTime.now();
    _pageSeq += 1;

    await _firestore
        .collection('usage_visits')
        .doc(_userId)
        .collection('visits')
        .doc(_visitId)
        .collection('pages')
        .doc(_currentPageId)
        .set({
          'screen': screen,
          'startedAt': FieldValue.serverTimestamp(),
          'sequence': _pageSeq,
        });
  }

  /// Page 종료
  Future<void> _endPage() async {
    if (_userId == null || _visitId == null) return;
    if (_currentPageId == null || _pageStart == null) return;

    final dur = DateTime.now().difference(_pageStart!).inMilliseconds;
    const minCutMs = 2000;
    final pageRef = _firestore
        .collection('usage_visits')
        .doc(_userId)
        .collection('visits')
        .doc(_visitId)
        .collection('pages')
        .doc(_currentPageId);

    if (dur < minCutMs) {
      await pageRef.delete();
    } else {
      await pageRef.update({
        'endedAt': FieldValue.serverTimestamp(),
        'durationMs': dur,
      });
      await _firestore
          .collection('usage_visits')
          .doc(_userId)
          .collection('visits')
          .doc(_visitId)
          .update({'pagesCount': FieldValue.increment(1)});
    }

    _currentPageId = null;
    _pageStart = null;
  }

  // -----------------------------
  // RouteObserver hooks
  // -----------------------------
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _startPage(route.settings.name ?? route.toString());
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _startPage(previousRoute.settings.name ?? previousRoute.toString());
    }
  }

  // -----------------------------
  // Lifecycle hooks
  // -----------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _endPage();
    }
    if (state == AppLifecycleState.detached) {
      endVisit(reason: 'background');
    }
  }
}
