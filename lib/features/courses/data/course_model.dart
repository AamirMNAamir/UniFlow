class CourseModel {
  const CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.lecturer,
    required this.semester,
    required this.progress,
  });

  final String id;
  final String code;
  final String name;
  final int credits;
  final String lecturer;
  final int semester;
  final double progress;
}