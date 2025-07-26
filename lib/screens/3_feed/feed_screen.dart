import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_first_app/constants/colors.dart';
import 'package:my_first_app/widget/empty_diary_card.dart';
import 'package:my_first_app/widget/diary_page_card.dart';
import 'package:my_first_app/widget/diary_page_indicator.dart';

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

  void _goToUpload() {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    Navigator.pushNamed(
      context,
      '/diary_upload',
      arguments: {'groupId': widget.groupId, 'date': formattedDate},
    );
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
                    if (!dailyDoc.exists) {
                      return const Text('해당 날짜의 질문이 없습니다.');
                    }

                    final questionRef =
                        dailyDoc['question'] as DocumentReference;

                    return FutureBuilder<DocumentSnapshot>(
                      future: questionRef.get(),
                      builder: (context, qSnap) {
                        if (!qSnap.hasData) return const SizedBox();
                        final data = qSnap.data!.data() as Map<String, dynamic>;
                        final questionText = data['content'] as String? ?? '';
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

                // 그림일기 리스트
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

                                  return DiaryPageCard(
                                    diaryData: data,
                                    isLastPage: index == diaryDocs.length - 1,
                                    isMyDiary: isMine,
                                    onAddPressed: _goToUpload,
                                  );
                                } else {
                                  // 마지막 + 페이지
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
