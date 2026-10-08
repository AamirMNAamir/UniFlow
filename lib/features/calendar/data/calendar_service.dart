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

  static CollectionReference<Map<String, dynamic>> _assignments(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('assignments');
  }

  // ---------------------------------------------------------------------------
  // CALENDAR EVENTS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // CALENDAR SOURCES
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // SAVE CALENDAR EVENT
  // ---------------------------------------------------------------------------

  static Future<void> saveCalendarEvent({
    required String userId,
    required CalendarEventModel event,
  }) async {
    await _events(userId).doc(event.id).set({
      'title': event.title,
      'description': event.description,
      'course': event.course,
      'type': event.type,
      'startTime': Timestamp.fromDate(event.startTime),
      'endTime': Timestamp.fromDate(event.endTime),
      'location': event.location,
      'source': event.source,
      'sourceEventId': event.sourceEventId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // SAVE ASSIGNMENT
  // ---------------------------------------------------------------------------

  static Future<void> saveAssignmentFromCalendar({
    required String userId,
    required CalendarEventModel event,
  }) async {
    await _assignments(userId).doc(event.id).set({
      'title': event.title,
      'course': event.course,
      'description': event.description,
      'dueDate': Timestamp.fromDate(event.endTime),
      'status': 'Pending',
      'priority': 'Medium',
      'progress': 0.0,
      'source': 'moodle',
      'sourceEventId': event.sourceEventId,
      'calendarEventId': event.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // IMPORT MULTIPLE EVENTS
  // ---------------------------------------------------------------------------

  static Future<Map<String, int>> importEvents({
    required String userId,
    required List<CalendarEventModel> events,
    required bool importAssignments,
  }) async {
    int importedEvents = 0;
    int importedAssignments = 0;

    for (final event in events) {
      await saveCalendarEvent(
        userId: userId,
        event: event,
      );

      importedEvents++;

      if (importAssignments && event.type == 'Assignment') {
        await saveAssignmentFromCalendar(
          userId: userId,
          event: event,
        );

        importedAssignments++;
      }
    }

    await _sources(userId).doc('moodle').set({
      'name': 'FEELS Calendar',
      'type': 'moodle',
      'enabled': true,
      'lastSyncedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return {
      'events': importedEvents,
      'assignments': importedAssignments,
    };
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

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