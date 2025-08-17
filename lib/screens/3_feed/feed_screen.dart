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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('daily_questions')
          .doc(formattedDate)
          .collection('diaries')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && groupCreatedAt == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        diaryDocs = snapshot.data?.docs ?? [];

        final displayDate = DateFormat(
          'yyyy-MM-dd EEEE',
          'ko_KR',
        ).format(selectedDate);

        final currentDiaryId =
            diaryDocs.isNotEmpty && currentPageIndex < diaryDocs.length
            ? diaryDocs[currentPageIndex].id
            : null;

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
                builder: (context, qSnapshot) {
                  if (!qSnapshot.hasData || !qSnapshot.data!.exists) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('해당 날짜의 질문이 없습니다.'),
                    );
                  }
                  final dailyDoc = qSnapshot.data!;
                  final data = dailyDoc.data() as Map<String, dynamic>;
                  final questionRef = data['question'];
                  if (questionRef == null ||
                      questionRef is! DocumentReference) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('질문이 없습니다.'),
                    );
                  }
                  return FutureBuilder<DocumentSnapshot>(
                    future: questionRef.get(),
                    builder: (context, qRefSnap) {
                      if (!qRefSnap.hasData) return const SizedBox();
                      final qData =
                          qRefSnap.data!.data() as Map<String, dynamic>;
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
                child: diaryDocs.isEmpty
                    ? EmptyDiaryCard(onAddPressed: _goToUpload)
                    : Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
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
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40.0,
                                          vertical: 8.0,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final hintData = data['hint'];

                                            final String hintText =
                                                (hintData is Map &&
                                                    hintData.containsKey(
                                                      'hint_content',
                                                    ))
                                                ? hintData['hint_content']
                                                : '작성된 힌트가 없습니다.';

                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('힌트'),
                                                content: Text(
                                                  hintText.isNotEmpty
                                                      ? hintText
                                                      : '작성된 힌트가 없습니다.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('닫기'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Text('힌트 보기'),
                                        ),
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
                      ),
              ),
              if (currentDiaryId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('댓글 보기'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: CommentSection(
                              groupId: widget.groupId,
                              date: formattedDate,
                              diaryId: currentDiaryId,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
