import 'package:flutter/material.dart';
import 'dart:ui';

class DiaryUploadScreen extends StatefulWidget {
  const DiaryUploadScreen({super.key});

  @override
  State<DiaryUploadScreen> createState() => _DiaryUploadScreenState();
}

class _DiaryUploadScreenState extends State<DiaryUploadScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

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
                const Text(
                  'Q. 오늘 본 것 중에 가장 인상 깊었던 것은?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '2025년 7월 2일 수요일',
                  style: TextStyle(fontSize: 14, color: Colors.teal),
                ),
                const SizedBox(height: 12),

                /// 🎨 드로잉 영역
                Listener(
                  onPointerDown: (event) {
                    setState(() {
                      isDrawing = true;
                      lines.add(DrawnLine(
                        point: event.localPosition,
                        color: selectedColor,
                      ));
                    });
                  },
                  onPointerMove: (event) {
                    if (!isDrawing) return;
                    setState(() {
                      lines.add(DrawnLine(
                        point: event.localPosition,
                        color: selectedColor,
                      ));
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
                    child: CustomPaint(
                      painter: DrawingPainter(lines: lines),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                /// 색상 팔레트
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
                            color: selectedColor == color ? Colors.black : Colors.transparent,
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
                  onPressed: () {
                    print("제목: ${titleController.text}");
                    print("내용: ${contentController.text}");
                  },
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
