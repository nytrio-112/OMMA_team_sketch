import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_first_app/constants/colors.dart';
import 'package:my_first_app/utils/firestore_helpers.dart';
import 'package:my_first_app/widget/diary_page_card.dart';
import 'package:my_first_app/widget/diary_page_indicator.dart';
import 'package:my_first_app/widget/comment_section.dart';
import 'package:my_first_app/screens/3_feed/diary_detail_screen.dart';
import 'dart:math' as math;

// ★ [ADD] 웹에서 브라우저 '뒤로가기(popstate)'까지 확실히 막기 위한 import
import 'package:flutter/foundation.dart' show kIsWeb; // ★ [ADD]
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // ★ [ADD]

class FeedScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUserId;

  const FeedScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime? groupCreatedAt;
  List<QueryDocumentSnapshot> diaryDocs = [];
  int currentPageIndex = 0;

  final PageController _pageController = PageController();

  // ★ [ADD] 웹 브라우저 뒤로가기(popstate) 무력화용 리스너
  html.EventListener? _popBlocker; // ★ [ADD]

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    _loadGroupCreatedAt();

    // ★ [ADD] 웹에서 브라우저 뒤로가기 제스처/버튼을 무력화
    if (kIsWeb) {
      // 현재 페이지를 히스토리에 푸시
      html.window.history.pushState(null, '', html.window.location.href);
      // 뒤로가기가 발생하면 다시 현재 페이지로 고정
      _popBlocker = (event) {
        html.window.history.pushState(null, '', html.window.location.href);
      };
      html.window.addEventListener('popstate', _popBlocker!);
    }
  }

  // ★ [ADD] 리스너 정리
  @override
  void dispose() {
    if (kIsWeb && _popBlocker != null) {
      html.window.removeEventListener('popstate', _popBlocker!);
    }
    super.dispose();
  }

  Future<void> _refreshDailyQuestion() async {
    setState(() {});
  }

  Future<void> _loadGroupCreatedAt() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupDoc.exists) {
      final timestamp = groupDoc['createdAt'] as Timestamp;
      setState(() {
        groupCreatedAt = timestamp.toDate();
      });
    }
  }

  bool get _canGoPrev {
    if (groupCreatedAt == null) return false;
    final prev = selectedDate.subtract(const Duration(days: 1));
    return !prev.isBefore(groupCreatedAt!);
  }

  bool get _canGoNext {
    final next = selectedDate.add(const Duration(days: 1));
    return !next.isAfter(DateTime.now());
  }

  void _goToPreviousDate() {
    if (!_canGoPrev) return;
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
      currentPageIndex = 0;
    });
  }

  void _goToNextDate() {
    if (!_canGoNext) return;
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
      currentPageIndex = 0;
    });
  }

  Future<void> _goToUpload() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      final groupType = groupDoc.data()?['groupType'] ?? '기타';

      final questionRef = await fetchAndSaveDailyQuestionIfNeeded(
        widget.groupId,
        groupType,
        formattedDate,
      );

      if (questionRef == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('질문이 없어 그림일기를 시작할 수 없습니다.')),
        );
        return;
      }

      await Navigator.pushNamed(
        context,
        '/diary_upload',
        arguments: {
          'groupId': widget.groupId,
          'date': formattedDate,
          'questionRef': questionRef,
        },
      );

      _refreshDailyQuestion();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final displayDate = DateFormat(
      'yyyy-MM-dd EEEE',
      'ko_KR',
    ).format(selectedDate);

    return PopScope(
      canPop: false, // ★ 추가: 스와이프/브라우저 back 등 라우트 pop 차단
      child: Scaffold(
        appBar: AppBar(
          // 필요하면 기본 뒤로가기 아이콘도 숨김
          // automaticallyImplyLeading: false, // ← 옵션
          title: Text(
            widget.groupName,
            style: const TextStyle(color: OmmaColors.green),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: groupCreatedAt == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [

                  const SizedBox(height: 12),
                  // 날짜 네비게이션
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TriangleButton(
                        direction: AxisDirection.left,
                        enabled: _canGoPrev,
                        onTap: _goToPreviousDate,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        displayDate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: OmmaColors.green, // ✅ 초록색
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TriangleButton(
                        direction: AxisDirection.right,
                        enabled: _canGoNext,
                        onTap: _goToNextDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('daily_questions')
                        .doc(formattedDate)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final dailyDoc = snapshot.data!;
                      if (!dailyDoc.exists) return const Text('해당 날짜의 질문이 없습니다.');

                      final data = dailyDoc.data() as Map<String, dynamic>;
                      final questionRef = data['question'];
                      if (questionRef == null ||
                          questionRef is! DocumentReference) {
                        return const Text('질문이 없습니다.');
                      }

                      return FutureBuilder<DocumentSnapshot>(
                        future: questionRef.get(),
                        builder: (context, qSnap) {
                          if (!qSnap.hasData) return const SizedBox();
                          final qData =
                              qSnap.data!.data() as Map<String, dynamic>;
                          final questionText = qData['content'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'Q. $questionText',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700, // Bold
                                color: Colors.black, // ✅ 검정
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('daily_questions')
                          .doc(formattedDate)
                          .collection('diaries')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        diaryDocs = snapshot.data!.docs;

                        if (diaryDocs.isEmpty) {
                          return Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: _UploadDiaryCard(onTap: _goToUpload),
                                ),
                              ),
                              DiaryPageIndicator(count: 1, current: 0),
                              const SizedBox(height: 8),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    controller: _pageController,
                                    physics: const NeverScrollableScrollPhysics(), // ← 스와이프 막기
                                    onPageChanged: (index) {
                                      setState(() {
                                        currentPageIndex = index;
                                      });
                                    },
                                    itemCount: diaryDocs.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index < diaryDocs.length) {
                                        final data =
                                            diaryDocs[index].data() as Map<String, dynamic>;
                                        final isMine =
                                            data['createdBy'] == widget.currentUserId;

                                        return ListView(
                                          padding: EdgeInsets.zero,
                                          children: [
                                            // 다이어리 카드
                                            DiaryPageCard(
                                              diaryData: data,
                                              isMyDiary: isMine,
                                              onToggleRevealed: () async {
                                                try {
                                                  final docRef = FirebaseFirestore.instance
                                                      .collection('groups')
                                                      .doc(widget.groupId)
                                                      .collection('daily_questions')
                                                      .doc(formattedDate)
                                                      .collection('diaries')
                                                      .doc(diaryDocs[index].id);

                                                  final newIsRevealed =
                                                      !(data['isRevealed'] ?? false);

                                                  await docRef.update({
                                                    'isRevealed': newIsRevealed,
                                                    'isAnonymous': newIsRevealed ? false : true,
                                                  });
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('오류 발생: $e')),
                                                  );
                                                }
                                              },
                                              onImageTap: () {
                                                final dateText = DateFormat(
                                                  'yyyy년 M월 d일 EEEE',
                                                  'ko_KR',
                                                ).format(selectedDate);

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => DiaryDetailScreen(
                                                      imageUrl: data['imageUrl'],
                                                      title: data['title'],
                                                      content: data['content'],
                                                      dateText: dateText,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),

                                            // ✅ 인디케이터를 댓글 위로 이동
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Center(
                                                child: DiaryPageIndicator(
                                                  count: diaryDocs.length, // 업로드 카드 제외한 실제 다이어리 개수
                                                  current: index, // 현재 페이지 인덱스
                                                ),
                                              ),
                                            ),

                                            // 댓글 섹션
                                            CommentSection(
                                              groupId: widget.groupId,
                                              date: formattedDate,
                                              diaryId: diaryDocs[index].id,
                                            ),
                                          ],
                                        );
                                      } else {
                                        // 마지막 페이지: 업로드 카드
                                        return Center(
                                          child: _UploadDiaryCard(onTap: _goToUpload),
                                        );
                                      }
                                    },
                                  ),

                                  // ── 2) 왼쪽 화살표 (첫 페이지에서 숨김) ────────────────
                                  if (currentPageIndex > 0) // ★ [ADDED] 첫 페이지면 숨김
                                    Positioned.fill(
                                      child: Align( // ★ [ADDED]
                                        alignment: Alignment.centerLeft, // ★ [ADDED]
                                        child: _PagerArrow( // ★ [ADDED] 새로 만든 위젯
                                          direction: AxisDirection.left,
                                          onTap: () {
                                            _pageController.previousPage(
                                              duration: const Duration(milliseconds: 220),
                                              curve: Curves.easeOut,
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                  // ── 3) 오른쪽 화살표 (마지막 '업로드 카드' 전까지만 보이게) ─────────
                                  if (currentPageIndex < diaryDocs.length) // ★ [ADDED]
                                    Positioned.fill(
                                      child: Align( // ★ [ADDED]
                                        alignment: Alignment.centerRight, // ★ [ADDED]
                                        child: _PagerArrow( // ★ [ADDED]
                                          direction: AxisDirection.right,
                                          onTap: () {
                                            _pageController.nextPage(
                                              duration: const Duration(milliseconds: 220),
                                              curve: Curves.easeOut,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 아래는 기존 보조 위젯들 (삭제/수정 없음)
// ─────────────────────────────────────────────────────────────────────────────

/// 업로드 카드 (플러스 아이콘만)
class _UploadDiaryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadDiaryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 298,
        height: 359,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFD9D9D9), // 회색 배경
        ),
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.black87, size: 26),
          ),
        ),
      ),
    );
  }
}

/// 초록색 삼각형 버튼
class _TriangleButton extends StatelessWidget {
  final AxisDirection direction;
  final bool enabled;
  final VoidCallback onTap;

  const _TriangleButton({
    required this.direction,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = enabled
        ? OmmaColors.green
        : OmmaColors.green.withOpacity(0.35);

    final double angle = (direction == AxisDirection.left) ? math.pi : 0.0;

    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 24,
      child: Transform.rotate(
        angle: angle,
        child: Icon(Icons.play_arrow, color: color, size: 22),
      ),
    );
  }
}

/// 좌우 페이지 넘김 화살표 버튼
class _PagerArrow extends StatelessWidget {
  final AxisDirection direction;
  final VoidCallback onTap;

  const _PagerArrow({
    required this.direction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = direction == AxisDirection.left;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isLeft ? Icons.chevron_left : Icons.chevron_right,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}