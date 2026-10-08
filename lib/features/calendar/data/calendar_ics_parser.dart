import 'dart:convert';

import 'package:icalendar_parser/icalendar_parser.dart';

import 'calendar_event_model.dart';

class CalendarIcsParser {
  CalendarIcsParser._();

  static List<CalendarEventModel> parse(String icsContent) {
    final calendar = ICalendar.fromString(icsContent);
    final json = calendar.toJson();

    final dynamic rawEvents = json['data'];

    if (rawEvents is! List) {
      return [];
    }

    final List<CalendarEventModel> events = [];

    for (final dynamic item in rawEvents) {
      if (item is! Map) {
        continue;
      }

      final Map<String, dynamic> event =
          Map<String, dynamic>.from(item);

      if ((event['type'] as String?)?.toUpperCase() !=
          'VEVENT') {
        continue;
      }

      final String title =
          _stringValue(event['summary']);

      if (title.isEmpty) {
        continue;
      }

      final DateTime? startTime =
          _parseDateTime(event['dtstart']);

      if (startTime == null) {
        continue;
      }

      final DateTime endTime =
          _parseDateTime(event['dtend']) ??
          startTime.add(const Duration(hours: 1));

      final String description =
          _stringValue(event['description']);

      final String location =
          _stringValue(event['location']);

      final String sourceEventId =
          _stringValue(event['uid']).isNotEmpty
              ? _stringValue(event['uid'])
              : _createFallbackId(
                  title,
                  startTime,
                );

      final String type =
          _detectEventType(
        title,
        description,
      );

      final String course =
          _detectCourse(
        title,
        description,
      );

      final String id =
          _createDocumentId(sourceEventId);

      events.add(
        CalendarEventModel(
          id: id,
          title: title,
          description: description,
          course: course,
          type: type,
          startTime: startTime,
          endTime: endTime,
          location: location,
          source: 'moodle',
          sourceEventId: sourceEventId,
        ),
      );
    }

    events.sort(
      (a, b) => a.startTime.compareTo(b.startTime),
    );

    return events;
  }

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value.trim();
    }

    if (value is Map) {
      final dynamic nested = value['value'] ?? value['text'] ?? value['dt'];

      if (nested is String) {
        return nested.trim();
      }
    }

    return value.toString().trim();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    String raw = _stringValue(value);

    if (raw.isEmpty) {
      return null;
    }

    // Handle ISO-8601 strings directly.
    final DateTime? isoDate =
        DateTime.tryParse(raw);

    if (isoDate != null) {
      return isoDate;
    }

    // Remove common iCalendar prefixes.
    raw = raw.trim();

    // UTC format:
    // 20261008T093000Z
    if (raw.endsWith('Z')) {
      final String valueWithoutZ =
          raw.substring(0, raw.length - 1);

      final DateTime? parsed =
          _parseBasicDateTime(valueWithoutZ);

      return parsed?.toUtc();
    }

    // Local iCalendar format:
    // 20261008T093000
    return _parseBasicDateTime(raw);
  }

  static DateTime? _parseBasicDateTime(String value) {
    final RegExp dateTimePattern = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T?(\d{2})?(\d{2})?(\d{2})?$',
    );

    final Match? match =
        dateTimePattern.firstMatch(value);

    if (match == null) {
      return null;
    }

    final int year =
        int.parse(match.group(1)!);

    final int month =
        int.parse(match.group(2)!);

    final int day =
        int.parse(match.group(3)!);

    final int hour =
        int.tryParse(match.group(4) ?? '0') ?? 0;

    final int minute =
        int.tryParse(match.group(5) ?? '0') ?? 0;

    final int second =
        int.tryParse(match.group(6) ?? '0') ?? 0;

    return DateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
  }

  static String _detectEventType(
    String title,
    String description,
  ) {
    final String text =
        '$title $description'.toLowerCase();

    if (_containsAny(text, [
      'assignment',
      'assignments',
      'coursework',
      'submission',
      'submit',
      'homework',
      'task',
    ])) {
      return 'Assignment';
    }

    if (_containsAny(text, [
      'quiz',
      'quizzes',
      'mcq',
      'test',
      'class test',
    ])) {
      return 'Quiz';
    }

    if (_containsAny(text, [
      'exam',
      'examination',
      'midterm',
      'mid-term',
      'final exam',
      'end semester',
    ])) {
      return 'Exam';
    }

    if (_containsAny(text, [
      'lab',
      'laboratory',
      'practical',
    ])) {
      return 'Lab';
    }

    if (_containsAny(text, [
      'project',
      'mini project',
      '2yp',
      'research',
    ])) {
      return 'Project';
    }

    if (_containsAny(text, [
      'lecture',
      'lesson',
      'class',
    ])) {
      return 'Lecture';
    }

    return 'Other';
  }

  static String _detectCourse(
    String title,
    String description,
  ) {
    final String text =
        '$title $description';

    // Examples:
    // CO2050
    // CO2070
    // EM2010
    // ENG4008

    final RegExp coursePattern = RegExp(
      r'\b[A-Z]{2,4}\d{4}\b',
      caseSensitive: false,
    );

    final Match? match =
        coursePattern.firstMatch(text);

    if (match == null) {
      return '';
    }

    return match.group(0)!.toUpperCase();
  }

  static bool _containsAny(
    String text,
    List<String> values,
  ) {
    for (final String value in values) {
      if (text.contains(value)) {
        return true;
      }
    }

    return false;
  }

  static String _createFallbackId(
    String title,
    DateTime startTime,
  ) {
    final String raw =
        '$title|${startTime.toIso8601String()}';

    return base64UrlEncode(
      utf8.encode(raw),
    );
  }

  static String _createDocumentId(
    String sourceEventId,
  ) {
    final String encoded =
        base64UrlEncode(
      utf8.encode(sourceEventId),
    );

    return encoded
        .replaceAll('/', '_')
        .replaceAll('+', '-')
        .replaceAll('=', '');
  }
}