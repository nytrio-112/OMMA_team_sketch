import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('그룹 만들기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              onChanged: (_) => _updateState(),
              decoration: const InputDecoration(
                labelText: '이 그룹의 이름은',
                helperText: '',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _relationship,
              items: const [
                DropdownMenuItem(value: '가족', child: Text('가족')),
                DropdownMenuItem(value: '친구', child: Text('친구')),
                DropdownMenuItem(value: '연인', child: Text('연인')),
                DropdownMenuItem(value: '기타', child: Text('기타')),
              ],
              onChanged: (value) {
                setState(() {
                  _relationship = value;
                  if (value != '가족') {
                    _roleController.clear();
                  }
                });
              },
              decoration: const InputDecoration(labelText: '우리의 관계는'),
            ),
            if (_relationship == '가족') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _roleController,
                onChanged: (_) => _updateState(),
                decoration: const InputDecoration(
                  labelText: '관계 속 나의 역할은',
                  helperText: 'ex. 엄마, 아빠, 아들, 딸',
                ),
              ),
            ],
            const SizedBox(height: 20),
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
                onPressed: _isCompleteEnabled && !_isLoading
                    ? _createTeam
                    : null,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
