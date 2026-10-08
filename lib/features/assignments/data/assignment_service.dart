import 'package:cloud_firestore/cloud_firestore.dart';

import 'assignment_model.dart';

class AssignmentService {
  AssignmentService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _assignments(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('assignments');
  }

  static Stream<List<AssignmentModel>> assignmentsStream(
    String userId,
  ) {
    return _assignments(userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final Timestamp? dueDateTimestamp =
            data['dueDate'] as Timestamp?;

        return AssignmentModel(
          id: doc.id,
          title: data['title'] as String? ?? '',
          course: data['course'] as String? ?? '',
          description: data['description'] as String? ?? '',
          dueDate: dueDateTimestamp?.toDate() ?? DateTime.now(),
          status: data['status'] as String? ?? 'Pending',
          priority: data['priority'] as String? ?? 'Medium',
          progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    });
  }

  static Future<void> addAssignment({
    required String userId,
    required String title,
    required String course,
    required String description,
    required DateTime dueDate,
    required String status,
    required String priority,
    required double progress,
  }) async {
    await _assignments(userId).add({
      'title': title.trim(),
      'course': course.trim(),
      'description': description.trim(),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'priority': priority,
      'progress': progress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateAssignment({
    required String userId,
    required String assignmentId,
    required String title,
    required String course,
    required String description,
    required DateTime dueDate,
    required String status,
    required String priority,
    required double progress,
  }) async {
    await _assignments(userId).doc(assignmentId).update({
      'title': title.trim(),
      'course': course.trim(),
      'description': description.trim(),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'priority': priority,
      'progress': progress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteAssignment({
    required String userId,
    required String assignmentId,
  }) async {
    await _assignments(userId).doc(assignmentId).delete();
  }
}