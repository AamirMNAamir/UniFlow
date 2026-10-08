class GpaCourseModel {
  const GpaCourseModel({
    required this.id,
    required this.courseName,
    required this.credits,
    required this.grade,
    required this.gradePoint,
  });

  final String id;
  final String courseName;
  final int credits;
  final String grade;
  final double gradePoint;

  factory GpaCourseModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return GpaCourseModel(
      id: id,
      courseName: map['courseName'] as String? ?? '',
      credits: (map['credits'] as num?)?.toInt() ?? 0,
      grade: map['grade'] as String? ?? 'F',
      gradePoint:
          (map['gradePoint'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseName': courseName,
      'credits': credits,
      'grade': grade,
      'gradePoint': gradePoint,
    };
  }
}