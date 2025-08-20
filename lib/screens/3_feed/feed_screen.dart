import 'dart:async';
import 'dart:math' as math;

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

  // 실제로 존재하는 날짜 문서 리스트
  List<DateTime> existingDates = [];

  List<QueryDocumentSnapshot> diaryDocs = [];
  int currentPageIndex = 0;

  final PageController _pageController = PageController();
  StreamSubscription<QuerySnapshot>? _datesSub;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    _subscribeDailyDates();
  }

  @override
  void dispose() {
    _datesSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // yyyy-MM-dd 형태의 날짜만 비교
  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // 오늘(자정 기준)
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ✅ 네비게이션 대상 날짜 리스트: existingDates + 오늘(중복 없이)
  List<DateTime> get _navDates {
    final list = <DateTime>[];
    // 기존 날짜들
    for (final d in existingDates) {
      if (!list.any((x) => _isSameDate(x, d))) list.add(d);
    }
    // 오늘 추가
    if (!list.any((x) => _isSameDate(x, _today))) {
      list.add(_today);
    }
    list.sort();
    return list;
  }

  void _subscribeDailyDates() {
    final col = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('daily_questions');

    // FieldPath.documentId 는 게터라서 () 붙이면 안 됨
    _datesSub = col.orderBy(FieldPath.documentId).snapshots().listen((qs) {
      final dates =
          qs.docs
              .map((d) {
                try {
                  return DateTime.parse(d.id); // yyyy-MM-dd
                } catch (_) {
                  return null;
                }
              })
              .whereType<DateTime>()
              .toList()
            ..sort();

      setState(() {
        existingDates = dates;

        final nav = _navDates;
        if (nav.isEmpty) {
          // 이론상 nav에는 최소한 오늘이 들어가므로 비어있지 않음
          selectedDate = _today;
          return;
        }

        // 현재 선택 날짜가 네비 대상에 없으면 가장 최근(=오늘 또는 마지막 문서날짜)로 스냅
        if (!nav.any((d) => _isSameDate(d, selectedDate))) {
          selectedDate = nav.last;
        }
      });
    });
  }

  Future<void> _refreshDailyQuestion() async {
    setState(() {});
  }

  // ✅ 좌/우 이동 가능 여부를 _navDates 기준으로 판정
  bool get _canGoPrev {
    final nav = _navDates;
    if (nav.isEmpty) return false;
    final idx = nav.indexWhere((d) => _isSameDate(d, selectedDate));
    return idx > 0;
  }

  bool get _canGoNext {
    final nav = _navDates;
    if (nav.isEmpty) return false;
    final idx = nav.indexWhere((d) => _isSameDate(d, selectedDate));
    return idx >= 0 && idx < nav.length - 1;
  }

  // ✅ 네비 대상 리스트 내에서만 이동 (오늘 포함)
  void _goToPreviousDate() {
    final nav = _navDates;
    if (nav.isEmpty) return;
    final idx = nav.indexWhere((d) => _isSameDate(d, selectedDate));
    if (idx > 0) {
      setState(() {
        selectedDate = nav[idx - 1];
        currentPageIndex = 0;
      });
    }
  }

  void _goToNextDate() {
    final nav = _navDates;
    if (nav.isEmpty) return;
    final idx = nav.indexWhere((d) => _isSameDate(d, selectedDate));
    if (idx >= 0 && idx + 1 < nav.length) {
      setState(() {
        selectedDate = nav[idx + 1];
        currentPageIndex = 0;
      });
    }
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

      _refreshDailyQuestion(); // 돌아오면 갱신
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: const TextStyle(color: OmmaColors.green),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
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
                  color: OmmaColors.green,
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

          // 질문 영역: 오늘에 문서가 없어도 '질문이 없습니다.'가 뜨고,
          // 아래에서 업로드 카드가 노출되어 새 문서를 만들 수 있다.
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection('daily_questions')
                .doc(formattedDate)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: SizedBox(
                    height: 20,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final dailyDoc = snapshot.data!;
              if (!dailyDoc.exists) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('해당 날짜의 질문이 없습니다.'),
                );
              }

              final data = dailyDoc.data() as Map<String, dynamic>;
              final questionRef = data['question'];
              if (questionRef == null || questionRef is! DocumentReference) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('질문이 없습니다.'),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: questionRef.get(),
                builder: (context, qSnap) {
                  if (!qSnap.hasData) {
                    return const SizedBox(height: 20);
                  }
                  final qData = qSnap.data!.data() as Map<String, dynamic>?;
                  final questionText = qData?['content'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Q. $questionText',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const Divider(height: 1),

          // 다이어리 리스트: 문서가 없으면 업로드 카드만 노출
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
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            currentPageIndex = index;
                          });
                        },
                        itemCount: diaryDocs.length + 1, // 마지막 업로드 카드 포함
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
                                        'isAnonymous': newIsRevealed
                                            ? false
                                            : true,
                                      });
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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

                                // 인디케이터(댓글 위)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Center(
                                    child: DiaryPageIndicator(
                                      count: diaryDocs.length,
                                      current: index,
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
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
        decoration: const BoxDecoration(color: Color(0xFFD9D9D9)),
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
