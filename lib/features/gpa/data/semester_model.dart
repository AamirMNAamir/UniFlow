class SemesterModel {
  const SemesterModel({
    required this.id,
    required this.name,
    required this.semesterNumber,
  });

  final String id;
  final String name;
  final int semesterNumber;

  factory SemesterModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SemesterModel(
      id: id,
      name: map['name'] as String? ?? 'Semester',
      semesterNumber:
          (map['semesterNumber'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'semesterNumber': semesterNumber,
    };
  }
}