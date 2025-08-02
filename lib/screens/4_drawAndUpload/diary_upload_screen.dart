import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

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
  Color selectedColor = Colors.orange;
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
    Colors.grey.shade200,
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

  bool _isInside(Offset point) {
    return point.dx >= 0 &&
        point.dx <= 350 &&
        point.dy >= 0 &&
        point.dy <= 200;
  }

  void _undoLastStroke() {
    setState(() {
      if (lines.isEmpty) return;
        // 마지막 선이 그려진 지점 찾기 (null 아닌 마지막)
        int last = lines.length - 1;
        while (last >= 0 && lines[last] == null) {
          last--;
        }

        // 이번에 지워야 할 구간 시작점 (null 이전까지)
        int first = last;
        while (first >= 0 && lines[first] != null) {
          first--;
        }

        // null 포함해서 전체 삭제
        lines.removeRange(first + 1, lines.length);
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

    final hintContent = hintResult['hint_content'] ?? '';
    final isAuthorRevealed = hintResult['isAuthorRevealed'] ?? false;

    if (hintContent.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('힌트를 입력해주세요.')));
      return;
    }

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
      final userNickname = userDoc.data()?['name'] ?? '익명';

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
            'createdByNickname': isAuthorRevealed ? userNickname : '익명',
            'isAuthorRevealed': isAuthorRevealed,
            'createdAt': FieldValue.serverTimestamp(),
            'isRevealed': false,
            'hint': {'hint_content': hintContent, 'isRevealed': false},
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('일기가 업로드되었습니다!')));
        Navigator.pop(context);
      }
    } catch (e) {
      print('업로드 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
    }
  }

  Future<Map<String, dynamic>?> showHintDialog(BuildContext context) async {
    final TextEditingController hintController = TextEditingController();
    ValueNotifier<bool> isEmpty = ValueNotifier(false);

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('간단한 힌트 작성하기'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hintController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '힌트를 입력하세요 (예: 우리가 어제 간 장소!)',
                  border: const OutlineInputBorder(),
                  errorText: isEmpty.value ? '힌트를 입력해주세요.' : null,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (hintController.text.trim().isEmpty) {
                      isEmpty.value = true;
                    } else {
                      Navigator.of(context).pop({
                        'hint_content': hintController.text.trim(),
                        'isAuthorRevealed': false,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('익명으로 업로드'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('or'),
                ),
                OutlinedButton(
                  onPressed: () {
                    if (hintController.text.trim().isEmpty) {
                      isEmpty.value = true;
                    } else {
                      Navigator.of(context).pop({
                        'hint_content': hintController.text.trim(),
                        'isAuthorRevealed': true,
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                  child: const Text('작성자 공개 업로드'),
                ),
              ],
            ),
          ],
        );
      },
    );
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: questionDocFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final questionText = data['content'] ?? '';
                    return Text(
                      'Q. $questionText',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: const TextStyle(fontSize: 14, color: Colors.teal),
                ),
                const SizedBox(height: 12),
                ClipRect(
                  child: RepaintBoundary(
                    key: canvasKey,
                    child: Listener(
                      onPointerDown: (event) {
                        final localPosition = event.localPosition;
                        // ✅ 입력 영역을 제한하는 조건 추가
                        if (_isInside(localPosition)) {
                          setState(() {
                            isDrawing = true;
                            lines.add(
                              DrawnLine(
                                point: localPosition,
                                color: selectedColor,
                              ),
                            );
                          });
                        }
                      },
                    onPointerMove: (event) {
                      if (!isDrawing) return;
                      final localPosition = event.localPosition;
                      // ✅ 입력 영역 제한 조건 추가
                      if (_isInside(localPosition)) {
                        setState(() {
                          lines.add(
                            DrawnLine(
                              point: localPosition,
                              color: selectedColor,
                            ),
                          );
                        });
                      }
                    },
                    onPointerUp: (_) {
                      setState(() {
                        isDrawing = false;
                        lines.add(null);
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        color: Colors.white,
                      ),
                      child: CustomPaint(painter: DrawingPainter(lines: lines)),
                    ),
                  ),
                ),
              ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...colorPalette.map((color) {
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
                            color: selectedColor == color
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
