import 'package:flutter/material.dart';
import 'package:my_first_app/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiaryPageCard extends StatefulWidget {
  final Map<String, dynamic> diaryData;
  final bool isLastPage;
  final bool isMyDiary;
  final VoidCallback? onAddPressed;

  final String groupId;
  final String date;
  final String diaryId;

  const DiaryPageCard({
    super.key,
    required this.diaryData,
    required this.isLastPage,
    required this.isMyDiary,
    this.onAddPressed,
    required this.groupId,
    required this.date,
    required this.diaryId,
  });

  @override
  State<DiaryPageCard> createState() => _DiaryPageCardState();
}

class _DiaryPageCardState extends State<DiaryPageCard> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
          'createdBy': user.uid,
          'nickname': '익명',
          'createdAt': FieldValue.serverTimestamp(),
        });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.diaryData['imageUrl'] ?? '';
    final title = widget.diaryData['title'] ?? '';
    final isRevealed = widget.diaryData['isRevealed'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != '')
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('(이미지를 불러올 수 없습니다)');
                },
              )
            else
              const Icon(Icons.image, size: 200, color: Colors.grey),

            const SizedBox(height: 12),
            Text(
              isRevealed ? title : '(작성자가 아직 내용을 공개하지 않았어요)',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            // 댓글 리스트 (스크롤 가능)
            SizedBox(
              height: 150,
              child: StreamBuilder<QuerySnapshot>(
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
                    padding: EdgeInsets.zero,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final data =
                          comments[index].data() as Map<String, dynamic>;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(data['nickname'] ?? '익명'),
                        subtitle: Text(data['content'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 댓글 입력창
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: '댓글을 입력해주세요'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitComment,
                ),
              ],
            ),

            // +버튼
            if (widget.isLastPage &&
                !widget.isMyDiary &&
                widget.onAddPressed != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: widget.onAddPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('그림일기 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OmmaColors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
