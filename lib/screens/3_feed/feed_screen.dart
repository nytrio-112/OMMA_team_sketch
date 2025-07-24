import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_first_app/constants/colors.dart';
import 'package:intl/date_symbol_data_local.dart';

class FeedScreen extends StatefulWidget {
  final String groupId; // 그룹 ID
  final String groupName; // 그룹 이름
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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR'); // 한국어 로케일 초기화
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
          // 날짜 선택 영역
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

          // 질문 표시 (Firestore에서 question ref 가져와야 함)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection('daily_questions')
                .doc(formattedDate)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final dailyQuestionData = snapshot.data!;
              final questionRef =
                  dailyQuestionData['question'] as DocumentReference;

              return FutureBuilder<DocumentSnapshot>(
                future: questionRef.get(),
                builder: (context, qSnap) {
                  if (!qSnap.hasData) return const SizedBox();
                  final questionText = qSnap.data!['content'] ?? '';
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

          // 그림일기 피드 (Stream으로 일기 목록 받아오기)
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final diaries = snapshot.data!.docs;

                if (diaries.isEmpty) {
                  return const Center(child: Text('아직 등록된 그림일기가 없어요.'));
                }

                return ListView.builder(
                  itemCount: diaries.length,
                  itemBuilder: (context, index) {
                    final diaryData =
                        diaries[index].data() as Map<String, dynamic>;
                    final diaryId = diaries[index].id;

                    return DiaryCard(
                      diaryId: diaryId,
                      diaryData: diaryData,
                      groupId: widget.groupId,
                      date: formattedDate,
                      currentUserId: widget.currentUserId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _goToPreviousDate() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _goToNextDate() {
    if (selectedDate.isBefore(DateTime.now())) {
      setState(() {
        selectedDate = selectedDate.add(const Duration(days: 1));
      });
    }
  }
}

// DiaryCard 위젯은 별도 파일로 분리 가능, 추후 상세 구현 필요
class DiaryCard extends StatelessWidget {
  final String diaryId;
  final Map<String, dynamic> diaryData;
  final String groupId;
  final String date;
  final String currentUserId;

  const DiaryCard({
    super.key,
    required this.diaryId,
    required this.diaryData,
    required this.groupId,
    required this.date,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: 여기서 diaryData['createdBy']와 currentUserId 비교 후
    // 본인 일기인지 아닌지에 따라 UI 달리 구성 (3-1 vs 3-2)
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 200,
        child: Center(child: Text('여기에 그림일기 썸네일 + 버튼/닉네임/댓글 등 구현 예정')),
      ),
    );
  }
}
