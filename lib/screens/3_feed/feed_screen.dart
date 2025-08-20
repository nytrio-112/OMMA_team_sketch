import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_first_app/constants/colors.dart';
import 'package:my_first_app/utils/firestore_helpers.dart';
import 'package:my_first_app/widget/empty_diary_card.dart';
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

  void _goToPreviousDate() {
    final prev = selectedDate.subtract(const Duration(days: 1));
    if (groupCreatedAt != null && !prev.isBefore(groupCreatedAt!)) {
      setState(() {
        selectedDate = prev;
        currentPageIndex = 0;
      });
    }
  }

  void _goToNextDate() {
    final next = selectedDate.add(const Duration(days: 1));
    if (!next.isAfter(DateTime.now())) {
      setState(() {
        selectedDate = next;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _goToPreviousDate,
                    ),
                    Text(
                      displayDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _goToNextDate,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
                        return EmptyDiaryCard(onAddPressed: _goToUpload);
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
                                            final isCurrentlyAnonymous =
                                                data['isAnonymous'] ?? true;

                                            await docRef.update({
                                              'isRevealed': newIsRevealed,
                                              'isAnonymous': newIsRevealed
                                                  ? false
                                                  : true, // 공개되면 false, 숨기면 true
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
                                      CommentSection(
                                        groupId: widget.groupId,
                                        date: formattedDate,
                                        diaryId: diaryDocs[index].id,
                                      ),
                                    ],
                                  );
                                } else {
                                  return Center(
                                    child: ElevatedButton.icon(
                                      onPressed: _goToUpload,
                                      icon: const Icon(Icons.add),
                                      label: const Text('그림일기 추가'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          DiaryPageIndicator(
                            count: diaryDocs.length + 1,
                            current: currentPageIndex,
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
