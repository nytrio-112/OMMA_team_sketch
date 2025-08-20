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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    _loadGroupCreatedAt();
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
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  currentPageIndex = index;
                                });
                              },
                              itemCount: diaryDocs.length + 1,
                              itemBuilder: (context, index) {
                                if (index < diaryDocs.length) {
                                  final data =
                                      diaryDocs[index].data()
                                          as Map<String, dynamic>;
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
                                            final docRef = FirebaseFirestore
                                                .instance
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
                                              SnackBar(
                                                content: Text('오류 발생: $e'),
                                              ),
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
                                              builder: (context) =>
                                                  DiaryDetailScreen(
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Center(
                                          child: DiaryPageIndicator(
                                            count: diaryDocs
                                                .length, // 업로드 카드 제외한 실제 다이어리 개수
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
