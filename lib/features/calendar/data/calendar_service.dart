import 'package:cloud_firestore/cloud_firestore.dart';

import 'calendar_event_model.dart';

class CalendarService {
  CalendarService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _events(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('calendar_events');
  }

  static CollectionReference<Map<String, dynamic>> _sources(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('calendar_sources');
  }

  static Stream<List<CalendarEventModel>> eventsStream(
    String userId,
  ) {
    return _events(userId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final Timestamp? startTimestamp =
            data['startTime'] as Timestamp?;

        final Timestamp? endTimestamp =
            data['endTime'] as Timestamp?;

        return CalendarEventModel(
          id: doc.id,
          title: data['title'] as String? ?? '',
          description:
              data['description'] as String? ?? '',
          course: data['course'] as String? ?? '',
          type: data['type'] as String? ?? 'Other',
          startTime:
              startTimestamp?.toDate() ?? DateTime.now(),
          endTime:
              endTimestamp?.toDate() ?? DateTime.now(),
          location:
              data['location'] as String? ?? '',
          source:
              data['source'] as String? ?? 'manual',
          sourceEventId:
              data['sourceEventId'] as String? ?? '',
        );
      }).toList();
    });
  }

  static Stream<List<Map<String, dynamic>>> sourcesStream(
    String userId,
  ) {
    return _sources(userId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  static Future<void> createCalendarSource({
    required String userId,
    required String name,
    required String type,
  }) async {
    await _sources(userId).doc(type).set({
      'name': name,
      'type': type,
      'enabled': true,
      'lastSyncedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSyncTime({
    required String userId,
    required String sourceId,
  }) async {
    await _sources(userId).doc(sourceId).set({
      'lastSyncedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteCalendarSource({
    required String userId,
    required String sourceId,
  }) async {
    await _sources(userId).doc(sourceId).delete();
  }

  static Future<void> deleteEvent({
    required String userId,
    required String eventId,
  }) async {
    await _events(userId).doc(eventId).delete();
  }
}