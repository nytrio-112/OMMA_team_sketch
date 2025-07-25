import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'joingroup_screen.dart';

class InvitingCodeScreen extends StatefulWidget {
  const InvitingCodeScreen({super.key});

  @override
  State<InvitingCodeScreen> createState() => _InvitingCodeScreenState();
}

class _InvitingCodeScreenState extends State<InvitingCodeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<FocusNode> _focusNodes = List.generate(
    5,
    (_) => FocusNode(),
  ); // 포커스 관리
  final List<TextEditingController> _controllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  bool _isLoading = false;

  String get _enteredCode =>
      _controllers.map((c) => c.text).join().toUpperCase();

  Future<void> _checkAndNavigate() async {
    final code = _enteredCode;

    if (code.length < 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("초대 코드를 모두 입력해주세요.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('invitationCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("잘못된 초대 코드입니다.")));
        return;
      }

      final groupDoc = querySnapshot.docs.first;
      final groupId = groupDoc.id;
      final groupType = groupDoc['groupType'] ?? '기타';

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              JoinGroupScreen(groupId: groupId, groupType: groupType),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInputBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
          width: 50,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                // 다음 입력 칸으로 자동 이동
                if (index < 4) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                } else {
                  FocusScope.of(context).unfocus();
                }
              }
              setState(() {});
            },
            keyboardType: TextInputType.text,
            textInputAction: index == 4
                ? TextInputAction.done
                : TextInputAction.next,
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // (1) 닫기 버튼
            Positioned(
              right: 16,
              top: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 24),
              ),
            ),

            // (2) 본문 내용
            Align(
              alignment: const Alignment(0, -0.4), // 위로 당김
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '팀 코드 입력하기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009B5B),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildInputBoxes(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 140,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkAndNavigate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009B5B),
                          shadowColor: const Color(0x55009B5B),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                '가입하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
