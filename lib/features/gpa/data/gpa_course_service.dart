import 'package:cloud_firestore/cloud_firestore.dart';

import 'gpa_course_model.dart';

class GpaCourseService {
  GpaCourseService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _courses({
    required String userId,
    required String semesterId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('semesters')
        .doc(semesterId)
        .collection('courses');
  }

  static Stream<List<GpaCourseModel>> watchCourses({
    required String userId,
    required String semesterId,
  }) {
    return _courses(
      userId: userId,
      semesterId: semesterId,
    ).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => GpaCourseModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  static Future<void> addCourse({
    required String userId,
    required String semesterId,
    required String courseName,
    required int credits,
    required String grade,
  }) async {
    final double gradePoint =
        gradePoints[grade] ?? 0.0;

    await _courses(
      userId: userId,
      semesterId: semesterId,
    ).add({
      'courseName': courseName.trim(),
      'credits': credits,
      'grade': grade,
      'gradePoint': gradePoint,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateCourse({
    required String userId,
    required String semesterId,
    required String courseId,
    required String courseName,
    required int credits,
    required String grade,
  }) async {
    final double gradePoint =
        gradePoints[grade] ?? 0.0;

    await _courses(
      userId: userId,
      semesterId: semesterId,
    ).doc(courseId).update({
      'courseName': courseName.trim(),
      'credits': credits,
      'grade': grade,
      'gradePoint': gradePoint,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteCourse({
    required String userId,
    required String semesterId,
    required String courseId,
  }) async {
    await _courses(
      userId: userId,
      semesterId: semesterId,
    ).doc(courseId).delete();
  }

  static double calculateGpa(
    List<GpaCourseModel> courses,
  ) {
    if (courses.isEmpty) {
      return 0.0;
    }

    int totalCredits = 0;
    double totalQualityPoints = 0.0;

    for (final course in courses) {
      totalCredits += course.credits;
      totalQualityPoints +=
          course.credits * course.gradePoint;
    }

    if (totalCredits == 0) {
      return 0.0;
    }

    return totalQualityPoints / totalCredits;
  }

  static int calculateTotalCredits(
    List<GpaCourseModel> courses,
  ) {
    return courses.fold(
      0,
      (total, course) => total + course.credits,
    );
  }

  static const Map<String, double> gradePoints = {
    'A+': 4.0,
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 3.0,
    'C+': 2.7,
    'C': 2.3,
    'C-': 2.0,
    'D+': 1.7,
    'D': 1.3,
    'D-': 1.0,
    'F': 0.0,
  };
}