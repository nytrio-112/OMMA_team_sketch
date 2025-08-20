import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../widget/bottomnavbar.dart';
import '../3_feed/feed_screen.dart';

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
    if (userData == null) return;

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
        if (data == null) return null;

        return {
          'groupId': groupId,
          'groupName': data['groupName'],
          'invitationCode': data['invitationCode'],
          'imageUrl': data['imageUrl'] ?? '',
          'membersCount': data['membersCount'] ?? 0,
        };
      }),
    );

    setState(() {
      _groupList = groupDocs.whereType<Map<String, dynamic>>().toList();
    });
  }

  Future<void> _uploadGroupImage(String groupId) async {
    final ref = FirebaseStorage.instance.ref().child(
      'group_profile/$groupId.jpg',
    );
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FeedScreen(
                                  groupId: group['groupId'],
                                  groupName: group['groupName'],
                                  currentUserId: _auth.currentUser!.uid,
                                ),
                              ),
                            );
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
                                          const SizedBox(height: 4),
                                          Text(
                                            '구성원 수: ${group['membersCount']}명',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton(
                onPressed: () async {
                  await _auth.signOut();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/intro',
                    (route) => false,
                  );
                },
                child: const Text(
                  '로그아웃',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
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
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 80,
          vertical: 40,
        ), // ✅ 가로 줄이고 세로 여백
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: OmmaColors.green.withOpacity(0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28), // ✅ 세로 길게 padding
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Center(
                    child: Text(
                      '그룹 가입하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: OmmaColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 첫 번째 버튼 (초록 배경)
                  _popupButtonFilled(
                    context,
                    text: '팀 코드로 입장하기',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/invitingcode');
                    },
                  ),

                  const SizedBox(height: 20), // ✅ 버튼 간격 여유
                  // 두 번째 버튼 (아웃라인)
                  _popupButtonOutlined(
                    context,
                    text: '새로운 그룹 만들기',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/makegroup');
                    },
                  ),
                ],
              ),

              // 닫기 버튼
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 22,
                    color: OmmaColors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 초록 배경 + 흰 글씨 버튼
Widget _popupButtonFilled(
  BuildContext context, {
  required String text,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: OmmaColors.green, // ✅ 초록 배경
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white, // ✅ 흰 글씨
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// 흰 배경 + 초록 테두리 버튼
Widget _popupButtonOutlined(
  BuildContext context, {
  required String text,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OmmaColors.green, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: OmmaColors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
