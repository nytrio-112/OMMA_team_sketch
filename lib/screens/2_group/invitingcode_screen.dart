import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'joingroup_screen.dart'; // 이 파일 만들어놨을 테니까 import 필요

class InvitingCodeScreen extends StatefulWidget {
  const InvitingCodeScreen({super.key});

  @override
  State<InvitingCodeScreen> createState() => _InvitingCodeScreenState();
}

class _InvitingCodeScreenState extends State<InvitingCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _checkAndNavigate() async {
    final enteredCode = _codeController.text.trim();

    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("코드를 입력해주세요.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('invitationCode', isEqualTo: enteredCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("팀 코드를 확인해주세요.")));
        return;
      }

      final groupDoc = querySnapshot.docs.first;
      final groupId = groupDoc.id;
      final groupType = groupDoc['groupType'] ?? '기타';

      // 역할/닉네임 입력 페이지로 이동
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀 코드 입력하기')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('초대 코드를 입력하세요'),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: '초대코드'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkAndNavigate,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('가입하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
