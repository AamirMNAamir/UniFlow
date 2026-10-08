import 'package:cloud_firestore/cloud_firestore.dart';

import 'semester_model.dart';

class SemesterService {
  SemesterService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _semesters(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('semesters');
  }

  static Stream<List<SemesterModel>> watchSemesters(
    String userId,
  ) {
    return _semesters(userId)
        .orderBy('semesterNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SemesterModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  static Future<void> addSemester({
    required String userId,
    required String name,
    required int semesterNumber,
  }) async {
    await _semesters(userId).add({
      'name': name.trim(),
      'semesterNumber': semesterNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSemester({
    required String userId,
    required String semesterId,
    required String name,
    required int semesterNumber,
  }) async {
    await _semesters(userId).doc(semesterId).update({
      'name': name.trim(),
      'semesterNumber': semesterNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteSemester({
    required String userId,
    required String semesterId,
  }) async {
    final CollectionReference<Map<String, dynamic>> courses =
        _semesters(userId)
            .doc(semesterId)
            .collection('courses');

    final QuerySnapshot<Map<String, dynamic>> courseSnapshot =
        await courses.get();

    final WriteBatch batch = _firestore.batch();

    for (final document in courseSnapshot.docs) {
      batch.delete(document.reference);
    }

    batch.delete(
      _semesters(userId).doc(semesterId),
    );

    await batch.commit();
  }
}