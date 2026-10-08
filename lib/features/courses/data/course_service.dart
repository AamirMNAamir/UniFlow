import 'package:cloud_firestore/cloud_firestore.dart';

import 'course_model.dart';

class CourseService {
  CourseService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _courses(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('courses');
  }

  /// Get all courses for a student in real time.
  static Stream<List<CourseModel>> coursesStream(
    String userId,
  ) {
    return _courses(userId)
        .orderBy('code')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return CourseModel(
          id: doc.id,
          code: data['code'] as String? ?? '',
          name: data['name'] as String? ?? '',
          credits: (data['credits'] as num?)?.toInt() ?? 0,
          lecturer: data['lecturer'] as String? ?? '',
          semester: (data['semester'] as num?)?.toInt() ?? 0,
          progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    });
  }

  /// Add a new course.
  static Future<void> addCourse({
    required String userId,
    required String code,
    required String name,
    required int credits,
    required String lecturer,
    required int semester,
    required double progress,
  }) async {
    await _courses(userId).doc(code.trim()).set({
      'code': code.trim(),
      'name': name.trim(),
      'credits': credits,
      'lecturer': lecturer.trim(),
      'semester': semester,
      'progress': progress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing course.
  static Future<void> updateCourse({
    required String userId,
    required String courseId,
    required String code,
    required String name,
    required int credits,
    required String lecturer,
    required int semester,
    required double progress,
  }) async {
    await _courses(userId).doc(courseId).update({
      'code': code.trim(),
      'name': name.trim(),
      'credits': credits,
      'lecturer': lecturer.trim(),
      'semester': semester,
      'progress': progress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a course.
  static Future<void> deleteCourse({
    required String userId,
    required String courseId,
  }) async {
    await _courses(userId).doc(courseId).delete();
  }
}