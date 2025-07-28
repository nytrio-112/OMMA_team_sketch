import 'package:cloud_firestore/cloud_firestore.dart';

Future<DocumentReference?> fetchAndSaveDailyQuestionIfNeeded(
  String groupId,
  String groupType,
  String date,
) async {
  final firestore = FirebaseFirestore.instance;
  final groupRef = firestore.collection('groups').doc(groupId);
  final questionDocRef = groupRef.collection('daily_questions').doc(date);

  print('🟡 [helper] groupId: $groupId, date: $date, groupType: $groupType');

  // Step 1. 그룹의 usedQuestions 불러오기
  final groupSnapshot = await groupRef.get();
  final groupData = groupSnapshot.data() as Map<String, dynamic>?;

  final usedQuestionIds =
      (groupData?['usedQuestions'] as List<dynamic>?)
          ?.map((id) => id.toString())
          .toSet() ??
      {};

  print('🚫 usedQuestionIds: $usedQuestionIds');

  // Step 2. 해당 날짜 문서 불러오기
  final dateDoc = await questionDocRef.get();
  if (dateDoc.exists) {
    final data = dateDoc.data() as Map<String, dynamic>;
    final existingQuestion = data['question'];

    if (existingQuestion is DocumentReference) {
      print('🟢 이미 question 존재함 → 재사용: ${existingQuestion.path}');
      return existingQuestion;
    } else {
      print('⚠️ 날짜 문서는 있으나 question이 없음 → 새로 추가 필요');
      // 아래로 이어서 새 질문을 뽑아 question 필드만 update
    }
  }

  // Step 3. 후보 질문 중에서 아직 사용 안 된 것만 필터링
  final candidateSnapshot = await firestore
      .collection('diary_questions')
      .where('recomm_groupType', arrayContains: groupType)
      .get();

  final unusedQuestions = candidateSnapshot.docs
      .where((doc) => !usedQuestionIds.contains(doc.id))
      .toList();

  print('🎯 사용 가능한 질문 개수: ${unusedQuestions.length}');

  if (unusedQuestions.isEmpty) {
    print('❌ 사용 가능한 질문이 없습니다.');
    return null;
  }

  // Step 4. 질문 선택 및 저장
  unusedQuestions.shuffle();
  final selected = unusedQuestions.first;
  final questionRef = selected.reference;

  print('✅ 선택된 질문: ${selected.id} / ${selected['content']}');

  // 문서가 이미 존재하면 → update / 존재하지 않으면 → set
  if (dateDoc.exists) {
    await questionDocRef.update({'question': questionRef});
  } else {
    await questionDocRef.set({'date': date, 'question': questionRef});
  }

  // Step 5. 그룹 usedQuestions 업데이트
  await groupRef.update({
    'usedQuestions': FieldValue.arrayUnion([selected.id]),
  });

  return questionRef;
}
