import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../widget/dropdown.dart';
import '../../widget/text_field.dart'; // 너가 만든 텍스트 필드

class MakeGroupScreen extends StatefulWidget {
  const MakeGroupScreen({super.key});

  @override
  State<MakeGroupScreen> createState() => _MakeGroupScreenState();
}

class _MakeGroupScreenState extends State<MakeGroupScreen> {
  final _groupNameController = TextEditingController();
  final _roleController = TextEditingController();
  final _nicknameController = TextEditingController();

  String? _relationship;
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _groupNameController.dispose();
    _roleController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _isCompleteEnabled {
    if (_groupNameController.text.trim().isEmpty || _relationship == null)
      return false;
    if (_relationship == '가족' && _roleController.text.trim().isEmpty)
      return false;
    return true;
  }

  String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Future<String> _getUniqueInvitationCode() async {
    String code;
    QuerySnapshot snapshot;

    do {
      code = _generateRandomString(6);
      snapshot = await _firestore
          .collection('teams')
          .where('invitationCode', isEqualTo: code)
          .get();
    } while (snapshot.docs.isNotEmpty);

    return code;
  }

  Future<void> _createTeam() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("로그인이 필요합니다.");

      final uid = currentUser.uid;
      final userRef = _firestore.collection('users').doc(uid);
      final teamID = _generateRandomString(10);
      final invitationCode = await _getUniqueInvitationCode();
      final now = FieldValue.serverTimestamp();

      final roleKey =
          (_relationship == '가족' && _roleController.text.trim().isNotEmpty)
          ? _roleController.text.trim()
          : '팀원 1';
      final nickname = _nicknameController.text.trim();

      final memberData = {
        'role': roleKey,
        'nickname': nickname,
        'isActive': true,
        'joinedAt': now,
      };

      final teamData = {
        'teamID': teamID,
        'invitationCode': invitationCode,
        'groupName': _groupNameController.text.trim(),
        'groupType': _relationship,
        'createdAt': now,
        'membersCount': 1,
        'isActive': true,
        'members': {uid: memberData},
        'startMember': userRef,
      };

      final userTeamData = {
        'role': roleKey,
        'nickname': nickname,
        'isActive': true,
        'joinedAt': now,
      };

      await _firestore.collection('teams').doc('team_$teamID').set(teamData);
      await _firestore.collection('users').doc(uid).set({
        'teams': {'team_$teamID': userTeamData},
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushNamed(context, '/mypage');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: OmmaColors.redAlert,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateState() => setState(() {});

  Widget _completeButton(VoidCallback onPressed, bool isEnabled) {
    return FractionallySizedBox(
      widthFactor: 0.8,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? OmmaColors.green : Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: isEnabled ? 6 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('완료', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '그룹 만들기',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: OmmaColors.green,
                  ),
                ),
                const SizedBox(height: 24),

                // 그룹 이름
                OmmaTextField(
                  controller: _groupNameController,
                  hintText: '그룹의 이름',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                ),

                // 관계 드롭다운
                OmmaDropdown(
                  value: _relationship,
                  hint: '그룹의 관계',
                  items: ['가족', '친구', '연인', '기타'],
                  onChanged: (val) {
                    setState(() {
                      _relationship = val;
                      _updateState();
                      if (val != '가족') _roleController.clear();
                    });
                  },
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                ),

                // 가족일 경우 역할 입력
                if (_relationship == '가족')
                  OmmaTextField(
                    controller: _roleController,
                    hintText: '관계 속 나의 역할은 (ex: 딸)',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),

                // 닉네임 입력
                OmmaTextField(
                  controller: _nicknameController,
                  hintText: '이 그룹에서 사용할 닉네임',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  '그룹 내 특별한 애칭이 있다면 적어보세요! (선택사항)',
                  style: TextStyle(fontSize: 12, color: OmmaColors.green),
                ),

                const SizedBox(height: 32),

                // 완료 버튼
                _completeButton(_createTeam, _isCompleteEnabled && !_isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
