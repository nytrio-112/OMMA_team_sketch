import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

// ✅ 프로젝트 색상
import 'package:my_first_app/constants/colors.dart';

class DiaryUploadScreen extends StatefulWidget {
  const DiaryUploadScreen({super.key});

  @override
  State<DiaryUploadScreen> createState() => _DiaryUploadScreenState();
}

class _DiaryUploadScreenState extends State<DiaryUploadScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final GlobalKey canvasKey = GlobalKey();

  List<DrawnLine?> lines = [];
  Color selectedColor = Colors.black;
  bool isDrawing = false;

  late String groupId;
  late String date;
  late DocumentReference questionRef;
  late Future<DocumentSnapshot> questionDocFuture;

  final List<Color> colorPalette = [
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.black,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      groupId = args['groupId'];
      date = args['date'];
      questionRef = args['questionRef'];

      setState(() {
        questionDocFuture = questionRef.get();
      });
    });
  }

  // ✅ 실제 캔버스 위젯의 사이즈를 기준으로 안/밖 판정
  Size _canvasSize() {
    final box = canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return const Size(268, 332);
    return box.size;
  }

  bool _isInside(Offset p) {
    final s = _canvasSize();
    return p.dx >= 0 && p.dx <= s.width && p.dy >= 0 && p.dy <= s.height;
  }

  void _undoLastStroke() {
    setState(() {
      if (lines.isEmpty) return;
      int last = lines.length - 1;
      while (last >= 0 && lines[last] == null) {
        last--;
      }
      int first = last;
      while (first >= 0 && lines[first] != null) {
        first--;
      }
      if (first + 1 < lines.length) {
        lines.removeRange(first + 1, lines.length);
      }
    });
  }

  Future<void> _handleUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (lines.where((line) => line != null).isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그림을 먼저 그려주세요!')));
      return;
    }

    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')));
      return;
    }

    final hintResult = await showHintDialog(context);
    if (hintResult == null) return;

    final String hintContent = ''; // ✅ 힌트 텍스트 저장 제거(빈 문자열)
    final bool isAuthorRevealed = hintResult['isAuthorRevealed'] ?? false;
    final bool isAnonymous = !isAuthorRevealed;

    try {
      final boundary =
          canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final imageBytes = byteData!.buffer.asUint8List();

      final storageRef = FirebaseStorage.instance.ref().child(
        'groups/$groupId/daily_questions/$date/diary_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      final imageUrl = await storageRef.getDownloadURL();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userNickname =
          userDoc.data()?['groups']?[groupId]?['nickname'] ?? '오류';

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('daily_questions')
          .doc(date)
          .collection('diaries')
          .add({
            'title': titleController.text,
            'content': contentController.text,
            'imageUrl': imageUrl,
            'createdBy': user.uid,
            'createdByNickname': userNickname,
            'isAuthorRevealed': isAuthorRevealed,
            'isAnonymous': isAnonymous,
            'createdAt': FieldValue.serverTimestamp(),
            'isRevealed': false,
            'hint': {'hint_content': hintContent, 'isRevealed': false},
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('일기가 업로드되었습니다!')));

        // ✅ FeedScreen으로 교체 이동
        Navigator.pushReplacementNamed(
          context,
          '/feed',
          arguments: {
            'groupId': groupId,
            'groupName': '', // 필요하다면 groupName 전달
            'currentUserId': user.uid,
          },
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('업로드 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
    }
  }

  /// ✅ 힌트 안내 멘트 제거 + 가운데 정렬 제목
  Future<Map<String, dynamic>?> showHintDialog(BuildContext context) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: OmmaColors.green.withOpacity(0.15)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

          // Title centered
          title: Center(
            child: Text(
              '업로드 방식 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: OmmaColors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 안내/설명 영역 제거
          content: const SizedBox.shrink(),

          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({'isAuthorRevealed': false});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OmmaColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('익명으로 업로드'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop({'isAuthorRevealed': true});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OmmaColors.green,
                      side: BorderSide(color: OmmaColors.green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('작성자 공개 업로드'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ✅ 드로잉 처리: 캔버스가 드래그 제스처를 선점하여 부모 스크롤 비활성화
  void _startAt(Offset p) {
    if (_isInside(p)) {
      setState(() {
        isDrawing = true;
        lines.add(DrawnLine(point: p, color: selectedColor));
      });
    }
  }

  void _updateAt(Offset p) {
    if (!isDrawing) return;
    if (_isInside(p)) {
      setState(() {
        lines.add(DrawnLine(point: p, color: selectedColor));
      });
    }
  }

  void _endStroke() {
    setState(() {
      isDrawing = false;
      lines.add(null); // 스트로크 구분자
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('그림일기 업로드')),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          // ✅ 화면 전체 스크롤은 유지 (부모는 기본 physics)
          child: SingleChildScrollView(
            child: Column(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: questionDocFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final questionText = data['content'] ?? '';
                    return Text(
                      'Q. $questionText',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: TextStyle(fontSize: 14, color: OmmaColors.green),
                ),
                const SizedBox(height: 12),

                // ✅ 여기서부터 "그림 영역 안에서만 스크롤 무력화"
                // GestureDetector가 onPan*을 모두 구현 → 부모 SingleChildScrollView의 스크롤 제스처보다 우선함
                // ✅ "그림 영역 안에서만 스크롤 무력화" + 충돌 없는 제스처 구성 (pan만 사용)
                ClipRect(
                  child: RepaintBoundary(
                    key: canvasKey,
                    child: Listener(
                      // 휠 스크롤(마우스/트랙패드)도 이 영역에선 효과 없게
                      onPointerSignal: (evt) {
                        /* intentionally eat scroll in canvas */
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        // pan만 사용 (vertical/horizontal 드래그 콜백 제거!)
                        onPanDown: (d) =>
                            _startAt(d.localPosition), // 먼저 잡아 부모 스크롤보다 우선
                        onPanStart: (d) => _startAt(d.localPosition),
                        onPanUpdate: (d) => _updateAt(d.localPosition),
                        onPanEnd: (_) => _endStroke(),

                        child: Container(
                          width: 268,
                          height: 332,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            color: Colors.white,
                          ),
                          child: CustomPaint(
                            painter: DrawingPainter(lines: lines),
                            size: const Size(268, 332),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...colorPalette.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedColor = color);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    IconButton(
                      icon: const Icon(Icons.undo),
                      tooltip: '되돌리기',
                      onPressed: _undoLastStroke,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(labelText: '제목:'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  style: const TextStyle(color: Colors.black),
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '글 작성하기',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OmmaColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('업로드'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DrawnLine {
  final Offset point;
  final Color color;
  DrawnLine({required this.point, required this.color});
}

class DrawingPainter extends CustomPainter {
  final List<DrawnLine?> lines;
  DrawingPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ 경계 밖 클립
    canvas.clipRect(Offset.zero & size);

    for (int i = 0; i < lines.length - 1; i++) {
      final current = lines[i];
      final next = lines[i + 1];
      if (current != null && next != null) {
        final paint = Paint()
          ..color = current.color
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.0;
        canvas.drawLine(current.point, next.point, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
