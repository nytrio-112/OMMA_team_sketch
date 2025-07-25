import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class JoinGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupType;

  const JoinGroupScreen({
    super.key,
    required this.groupId,
    required this.groupType,
  });

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _roleController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final List<String> _relationshipOptions = [
    '엄마',
    '아빠',
    '딸',
    '아들',
    '할머니',
    '할아버지',
    '기타',
  ];

  Future<void> _joinGroup() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("로그인이 필요합니다.");
      final uid = currentUser.uid;
      final now = FieldValue.serverTimestamp();

      final groupRef = _firestore.collection('groups').doc(widget.groupId);
      final groupSnap = await groupRef.get();
      final groupData = groupSnap.data();

      if (groupData == null) throw Exception("팀 정보를 찾을 수 없습니다.");

      final membersCount = (groupData['membersCount'] ?? 0) as int;
      final nickname = _nicknameController.text.trim();

      String role = '';
      if (widget.groupType == '가족') {
        if (_selectedRole == null || _selectedRole!.isEmpty) {
          throw Exception("역할을 선택해주세요.");
        }
        role = _selectedRole!;
      } else {
        role = '팀원 ${membersCount + 1}';
      }

      final memberData = {
        'role': role,
        'nickname': nickname,
        'isActive': true,
        'joinedAt': now,
      };

      final userGroupData = {
        'role': role,
        'nickname': nickname,
        'isActive': true,
        'joinedAt': now,
      };

      await groupRef.update({
        'members.$uid': memberData,
        'membersCount': FieldValue.increment(1),
      });

      await _firestore.collection('users').doc(uid).set({
        'groups': {widget.groupId: userGroupData},
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
      setState(() => _isLoading = false);
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.4),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '그룹 가입하기',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: OmmaColors.green,
                    ),
                  ),
                  const SizedBox(height: 60),
                  if (isFamily) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: OmmaColors.green.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('관계 속 나'),
                        ),
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: _relationshipOptions.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedRole = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: OmmaColors.green.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        hintText: '이 그룹에서 사용할 닉네임',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '그룹 내 특별한 애칭이 있다면 적어보세요!',
                    style: TextStyle(fontSize: 12, color: OmmaColors.green),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 140,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _joinGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OmmaColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        shadowColor: Colors.grey,
                        elevation: 6,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('완료', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
