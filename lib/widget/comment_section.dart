import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CommentSection extends StatefulWidget {
  final String groupId;
  final String date;
  final String diaryId;

  const CommentSection({
    super.key,
    required this.groupId,
    required this.date,
    required this.diaryId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 댓글 작성 시간 포맷 함수
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return DateFormat('yyyy.MM.dd HH:mm').format(dt);
  }

  // 댓글 저장
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();

    // nickname 불러오기
    final nickname =
        userData?['groups']?[widget.groupId]?['nickname'] ?? '정보없음';

    // 댓글 저장
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('daily_questions')
        .doc(widget.date)
        .collection('diaries')
        .doc(widget.diaryId)
        .collection('comments')
        .add({
          'content': content,
          'createdBy': userRef,
          'nickname': nickname,
          'createdAt': FieldValue.serverTimestamp(),
        });

    _commentController.clear();

    // 자동 스크롤
    await Future.delayed(const Duration(milliseconds: 300));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 댓글 리스트
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection('daily_questions')
                .doc(widget.date)
                .collection('diaries')
                .doc(widget.diaryId)
                .collection('comments')
                .orderBy('createdAt')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final comments = snapshot.data!.docs;

              return ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final data = comments[index].data() as Map<String, dynamic>;
                  final nickname = data['nickname'] ?? '정보없음';
                  final content = data['content'] ?? '';
                  final createdAt = data['createdAt'] as Timestamp?;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$nickname: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(child: Text(content)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatTimestamp(createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 8),

          // 댓글 입력창
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: '댓글을 입력해주세요',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.green),
                onPressed: _submitComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
