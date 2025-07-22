import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = '';
  Map<String, dynamic> _teamsMap = {};
  List<Map<String, dynamic>> _teamList = [];

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
        _teamsMap = Map<String, dynamic>.from(userData['teams'] ?? {});
      });

      final activeTeams = _teamsMap.entries
          .where((e) => e.value['isActive'] == true)
          .map((e) => e.key)
          .toList();

      final teamDocs = await Future.wait(
        activeTeams.map((teamId) async {
          final doc = await _firestore.collection('teams').doc(teamId).get();
          final data = doc.data();
          if (data != null) {
            return {
              'teamId': teamId,
              'groupName': data['groupName'],
              'groupType': data['groupType'],
              'invitationCode': data['invitationCode'],
              'membersCount': data['membersCount'],
            };
          }
          return null;
        }),
      );

      setState(() {
        _teamList = teamDocs.whereType<Map<String, dynamic>>().toList();
      });
    }
  }

  Future<void> _leaveTeam(String teamId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{
      'members.$uid.isActive': false,
      'membersCount': FieldValue.increment(-1),
    };

    final userUpdate = {'teams.$teamId.isActive': false};

    await _firestore.collection('teams').doc(teamId).update(updates);
    await _firestore.collection('users').doc(uid).update(userUpdate);

    await _loadUserData(); // 새로고침
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/intro',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('$_userName님의 OMMA', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Expanded(
              child: _teamList.isEmpty
                  ? const Center(child: Text('가입된 팀이 없습니다.'))
                  : ListView.builder(
                      itemCount: _teamList.length,
                      itemBuilder: (context, index) {
                        final team = _teamList[index];
                        return Card(
                          child: ListTile(
                            title: Text(team['groupName'] ?? ''),
                            subtitle: Text(
                              '${team['groupType']} • 코드: ${team['invitationCode']} • 인원: ${team['membersCount']}명',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'leave') {
                                  _leaveTeam(team['teamId']);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'leave',
                                  child: Text('팀 나가기'),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, '/feed');
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/onboarding');
                },
                icon: const Icon(Icons.add),
                label: const Text(''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
