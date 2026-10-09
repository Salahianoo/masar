import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:masar/core/utils/json_utils.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/domain/repositories/masar_repository.dart';
import 'package:masar/data/repositories/firebase_google_account_service.dart';

/// The production adapter for CONTRACT §6. Student writes use callables only.
class FirebaseMasarRepository implements MasarRepository {
  FirebaseMasarRepository({FirebaseApp? app})
      : _auth = FirebaseAuth.instanceFor(app: app ?? Firebase.app()),
        _db = FirebaseFirestore.instanceFor(app: app ?? Firebase.app()),
        _functions = FirebaseFunctions.instanceFor(
          app: app ?? Firebase.app(),
          region: 'europe-west1',
        );

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('سجّل دخولك أولاً');
    return uid;
  }

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async =>
      asJsonMap((await _functions.httpsCallable(name).call<Map<String, dynamic>>(data)).data);

  @override
  Future<void> signIn() async {
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await FirebaseGoogleAccountService.initializeGoogle();
    await GoogleSignIn.instance.signOut();
  }

  @override
  Future<UserProfile?> currentProfile() async {
    final doc = await _db.doc('users/$_uid').get();
    if (!doc.exists) return null;
    return UserProfile(uid: _uid, displayName: doc.data()?['displayName'] as String? ?? '');
  }

  @override
  Future<void> updateProfile(String displayName) async {
    await _call('updateProfile', {'displayName': displayName});
  }

  @override
  Future<AppConfig> config() async {
    final doc = await _db.doc('config/app').get();
    if (!doc.exists) throw StateError('إعدادات التطبيق غير متاحة حالياً');
    return AppConfig.fromJson(doc.data()!);
  }

  @override
  Future<List<Subject>> subjects() async {
    final docs = await _db.collection('subjects').where('active', isEqualTo: true).get();
    return docs.docs.map((d) => Subject.fromJson({'id': d.id, ...d.data()})).toList();
  }

  @override
  Future<List<Concept>> concepts(String subjectId) async {
    final docs = await _db.collection('subjects/$subjectId/concepts').get();
    final values = docs.docs.map((d) => Concept.fromJson({
          'id': d.id,
          'subjectId': subjectId,
          ...d.data(),
        })).toList();
    values.sort((a, b) => a.order.compareTo(b.order));
    return values;
  }

  @override
  Future<void> enroll(String subjectId, DateTime examDate) async {
    await _call('enroll', {'subjectId': subjectId, 'examDate': dateToIso(examDate)});
  }

  @override
  Future<List<Enrollment>> enrollments() async {
    final docs = await _db.collection('users/$_uid/enrollments').get();
    return docs.docs.map((d) => _enrollment(d.id, d.data())).toList();
  }

  Enrollment _enrollment(String id, Map<String, dynamic> data) => Enrollment(
        subjectId: data['subjectId'] as String? ?? id,
        examDate: (data['examDate'] as Timestamp).toDate(),
        diagnosticDone: data['diagnosticDone'] as bool? ?? false,
        readiness: asInt(data['readiness']),
      );

  @override
  Stream<SubjectProgress> progress(String subjectId) async* {
    final knownConcepts = await concepts(subjectId);
    final enrollmentDoc = await _db.doc('users/$_uid/enrollments/$subjectId').get();
    if (!enrollmentDoc.exists) throw StateError('سجّل المادة أولاً');
    final enrollment = _enrollment(subjectId, enrollmentDoc.data()!);
    yield* _db.doc('users/$_uid/mastery/$subjectId').snapshots().map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final states = data['concepts'] as Map<String, dynamic>? ?? {};
      final items = knownConcepts.map((concept) {
        final state = states[concept.id] as Map<String, dynamic>? ?? {};
        final attempts = asInt(state['attempts']);
        final theta = (state['theta'] as num? ?? -1).toDouble();
        final mastery = attempts == 0 ? 0 : (100 / (1 + math.exp(-theta))).round();
        final status = attempts == 0
            ? MasteryStatus.unknown
            : mastery < 40
                ? MasteryStatus.weak
                : mastery < 70
                    ? MasteryStatus.medium
                    : MasteryStatus.strong;
        return ConceptMastery(
          conceptId: concept.id,
          name: concept.name,
          weight: concept.weight,
          mastery: mastery,
          attempts: attempts,
          status: status,
        );
      }).toList()..sort((a, b) => b.weight.compareTo(a.weight));
      final readiness = asInt(data['readiness']);
      return SubjectProgress(
        subjectId: subjectId,
        readiness: readiness,
        projectedReadiness: math.min(90, readiness + 7 * enrollment.daysLeft),
        concepts: items,
      );
    });
  }

  @override
  Future<List<Question>> startDiagnostic(String subjectId) async {
    final data = await _call('startDiagnostic', {'subjectId': subjectId});
    return asJsonList(data['questions']).map(Question.fromJson).toList();
  }

  @override
  Future<SubjectProgress> completeDiagnostic(String subjectId) async =>
      SubjectProgress.fromJson(await _call('completeDiagnostic', {'subjectId': subjectId}));

  @override
  Future<TodayPlan> todayPlan(String subjectId) async =>
      TodayPlan.fromJson(await _call('todayPlan', {'subjectId': subjectId}));

  @override
  Future<Question?> nextQuestion(String subjectId, {String? conceptId}) async {
    final data = await _call('nextQuestion', {
      'subjectId': subjectId,
      'conceptId': ?conceptId,
    });
    return data['question'] == null ? null : Question.fromJson(asJsonMap(data['question']));
  }

  @override
  Future<AnswerResult> submitAnswer({
    required String questionId,
    required String chosen,
    required int ms,
    required AnswerSource source,
  }) async =>
      AnswerResult.fromJson(await _call('submitAnswer', {
        'questionId': questionId,
        'chosen': chosen,
        'ms': ms,
        'source': source.name,
      }));

  @override
  Future<List<Exam>> exams(String subjectId) async {
    final docs = await _db.collection('exams').where('subjectId', isEqualTo: subjectId).get();
    final values = docs.docs.map((d) => (
          order: asInt(d.data()['order']),
          exam: Exam.fromJson({'id': d.id, ...d.data()}),
        )).toList();
    values.sort((a, b) => a.order.compareTo(b.order));
    return values.map((entry) => entry.exam).toList();
  }

  @override
  Future<List<Question>> examQuestions(String examId) async {
    final docs = await _db.collection('questions').where('examId', isEqualTo: examId).get();
    // Awaiting the contract's paper-order field before this list is sorted.
    return docs.docs.map((d) => Question.fromJson({'id': d.id, ...d.data()})).toList();
  }

  @override
  Future<String> askMentor({
    required String subjectId,
    String? conceptId,
    required List<ChatMessage> messages,
  }) async {
    final data = await _call('askMentor', {
      'subjectId': subjectId,
      'conceptId': ?conceptId,
      'messages': messages.map((message) => message.toJson()).toList(),
    });
    return data['reply'] as String;
  }

  @override
  Future<List<ReadinessPoint>> readinessHistory(String subjectId) async {
    final doc = await _db.doc('users/$_uid/mastery/$subjectId').get();
    final history = doc.data()?['history'] as Map<String, dynamic>? ?? {};
    final days = history.entries.map((entry) => ReadinessPoint(
          day: DateTime.parse(entry.key),
          readiness: asInt(entry.value),
        )).toList();
    days.sort((a, b) => a.day.compareTo(b.day));
    return days;
  }
}
