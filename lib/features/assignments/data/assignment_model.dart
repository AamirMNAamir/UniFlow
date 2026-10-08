class AssignmentModel {
  const AssignmentModel({
    required this.id,
    required this.title,
    required this.course,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.progress,
  });

  final String id;
  final String title;
  final String course;
  final String description;
  final DateTime dueDate;
  final String status;
  final String priority;
  final double progress;
}