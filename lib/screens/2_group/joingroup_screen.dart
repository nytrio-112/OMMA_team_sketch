import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class JoinGroupScreen extends StatefulWidget {
  final String teamId;
  final String groupType;

  const JoinGroupScreen({
    super.key,
    required this.teamId,
    required this.groupType,
  });

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _roleController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _joinTeam() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("로그인이 필요합니다.");
      final uid = currentUser.uid;
      final userRef = _firestore.collection('users').doc(uid);
      final now = FieldValue.serverTimestamp();

      final teamRef = _firestore.collection('teams').doc(widget.teamId);
      final teamSnap = await teamRef.get();
      final teamData = teamSnap.data();

      if (teamData == null) throw Exception("팀 정보를 찾을 수 없습니다.");

      final membersCount = (teamData['membersCount'] ?? 0) as int;
      final nickname = _nicknameController.text.trim();

      String role = '';
      if (widget.groupType == '가족') {
        if (_roleController.text.trim().isEmpty) {
          throw Exception("역할을 입력해주세요.");
        }
        role = _roleController.text.trim();
      } else {
        role = '팀원 ${membersCount + 1}';
      }

      final memberData = {
        'role': role,
        'nickname': nickname,
        'isActive': true,
        'joinedAt': now,
      };

      final userTeamData = {
        'role': role,
        'nickname': nickname,
        'isActive': true,
        'joinedAt': now,
      };

      // teams 업데이트
      await teamRef.update({
        'members.$uid': memberData,
        'membersCount': FieldValue.increment(1),
      });

      // users 업데이트
      await _firestore.collection('users').doc(uid).set({
        'teams': {widget.teamId: userTeamData},
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushNamed(context, '/mypage');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: OmmaColors.redAlert,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _roleController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFamily = widget.groupType == '가족';

    return Scaffold(
      appBar: AppBar(title: const Text('그룹 가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isFamily) ...[
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: '관계 속 나의 역할',
                  helperText: 'ex. 엄마, 아빠, 아들, 딸',
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '이 그룹에서 사용할 닉네임',
                helperText: '그룹 내 특별한 애칭이 있다면 적어보세요! (선택사항)',
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _joinTeam,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('가입 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
