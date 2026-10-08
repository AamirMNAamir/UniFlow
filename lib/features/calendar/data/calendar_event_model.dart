class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.course,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.source,
    required this.sourceEventId,
  });

  final String id;
  final String title;
  final String description;
  final String course;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String source;
  final String sourceEventId;
}