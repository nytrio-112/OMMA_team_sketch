import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/colors.dart';
import '../../widget/bottomnavbar.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = '';
  List<Map<String, dynamic>> _groupList = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();

    if (userData != null) {
      setState(() {
        _userName = userData['name'] ?? '';
      });

      final groupsMap = Map<String, dynamic>.from(userData['groups'] ?? {});
      final activeGroups = groupsMap.entries
          .where((e) => e.value['isActive'] == true)
          .map((e) => e.key)
          .toList();

      final groupDocs = await Future.wait(
        activeGroups.map((groupId) async {
          final doc = await _firestore.collection('groups').doc(groupId).get();
          final data = doc.data();
          if (data != null) {
            return {
              'groupId': groupId,
              'groupName': data['groupName'],
              'invitationCode': data['invitationCode'],
              'imageUrl': data['imageUrl'] ?? '',
            };
          }
          return null;
        }),
      );

      setState(() {
        _groupList = groupDocs.whereType<Map<String, dynamic>>().toList();
      });
    }
  }

  Future<void> _uploadGroupImage(String groupId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final ref = FirebaseStorage.instance.ref().child(
      'group_profile/$groupId.jpg',
    );

    await ref.putFile(File(picked.path));
    final imageUrl = await ref.getDownloadURL();

    await _firestore.collection('groups').doc(groupId).update({
      'imageUrl': imageUrl,
    });

    _loadUserData();
  }

  Future<void> _leaveGroup(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('groups').doc(groupId).update({
      'members.$uid.isActive': false,
      'membersCount': FieldValue.increment(-1),
    });

    await _firestore.collection('users').doc(uid).update({
      'groups.$groupId.isActive': false,
    });

    _loadUserData();
  }

  void _showGroupMenu(String groupId, String code) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('팀 코드 공유하기'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('팀 코드가 복사되었어요!')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('채팅방 나가기'),
            onTap: () {
              Navigator.pop(context);
              _leaveGroup(groupId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_userName님의 ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'OMMA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: OmmaColors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: _groupList.isEmpty
                  ? const Center(child: Text('가입된 팀이 없습니다.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _groupList.length,
                      itemBuilder: (context, index) {
                        final group = _groupList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/feed');
                          },
                          child: Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 30,
                                ),
                                decoration: BoxDecoration(
                                  color: OmmaColors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 점 세 개 메뉴
                                    GestureDetector(
                                      onTap: () => _showGroupMenu(
                                        group['groupId'],
                                        group['invitationCode'],
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 16),
                                        child: Icon(
                                          Icons.more_vert,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    // 그룹 정보
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group['groupName'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Text(
                                            '팀 코드: ${group['invitationCode']}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 프로필 이미지 업로드
                                    GestureDetector(
                                      onTap: () =>
                                          _uploadGroupImage(group['groupId']),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          image: group['imageUrl'] != ''
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    group['imageUrl'],
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: group['imageUrl'] == ''
                                            ? const Icon(
                                                Icons.add,
                                                color: OmmaColors.green,
                                                size: 28,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                showJoinGroupDialog(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: OmmaColors.green.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: OmmaColors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showJoinGroupDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    '그룹 가입하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: OmmaColors.green,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _popupButton(
                    context,
                    text: '팀 코드로 입장하기',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/invitingcode');
                    },
                  ),
                  const SizedBox(height: 16),
                  _popupButton(
                    context,
                    text: '새로운 그룹 만들기',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/makegroup');
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _popupButton(
  BuildContext context, {
  required String text,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: OmmaColors.green.withOpacity(0.3),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: OmmaColors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
