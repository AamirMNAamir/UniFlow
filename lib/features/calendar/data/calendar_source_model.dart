class CalendarSourceModel {
  const CalendarSourceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
    required this.lastSyncedAt,
  });

  final String id;
  final String name;
  final String type;
  final bool enabled;
  final DateTime? lastSyncedAt;
}