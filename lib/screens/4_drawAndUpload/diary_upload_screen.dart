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

  final List<Color> colorPalette = [
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.black,
    Colors.grey.shade200,
  ];

  Future<void> _handleUpload(String groupId, String date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🎨 1. 캔버스 → 이미지로 캡처
      final boundary =
          canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final imageBytes = byteData!.buffer.asUint8List();

      // ☁️ 2. Firebase Storage에 업로드
      final storageRef = FirebaseStorage.instance.ref().child(
        'groups/$groupId/daily_questions/$date/diary_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      final imageUrl = await storageRef.getDownloadURL();

      // 📝 3. Firestore에 정보 저장
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('daily_questions')
          .doc(date)
          .collection('diaries')
          .doc()
          .set({
            'title': titleController.text,
            'content': contentController.text,
            'imageUrl': imageUrl,
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'isRevealed': false,
            'hint': {'hint_content': '', 'isRevealed': false},
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

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final groupId = args['groupId'];
    final date = args['date'];

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
                const Text(
                  'Q. 오늘 본 것 중에 가장 인상 깊었던 것은?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: const TextStyle(fontSize: 14, color: Colors.teal),
                ),
                const SizedBox(height: 12),

                /// 🎨 드로잉 캔버스
                RepaintBoundary(
                  key: canvasKey,
                  child: Listener(
                    onPointerDown: (event) {
                      setState(() {
                        isDrawing = true;
                        lines.add(
                          DrawnLine(
                            point: event.localPosition,
                            color: selectedColor,
                          ),
                        );
                      });
                    },
                    onPointerMove: (event) {
                      if (!isDrawing) return;
                      setState(() {
                        lines.add(
                          DrawnLine(
                            point: event.localPosition,
                            color: selectedColor,
                          ),
                        );
                      });
                    },
                    onPointerUp: (_) {
                      setState(() {
                        isDrawing = false;
                        lines.add(null); // 선 끊기
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

                const SizedBox(height: 8),

                /// 🎨 색상 팔레트
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: colorPalette.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
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
                  onPressed: () => _handleUpload(groupId, date),
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
