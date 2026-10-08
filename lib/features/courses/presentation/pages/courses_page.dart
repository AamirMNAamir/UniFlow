import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/data/auth_service.dart';
import '../../data/course_model.dart';
import '../../data/course_service.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _courseIcon(String code) {
    if (code.startsWith('CO20')) {
      return Icons.computer_rounded;
    }

    if (code.contains('54')) {
      return Icons.psychology_rounded;
    }

    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please sign in to view your courses.'),
      );
    }

    return StreamBuilder<List<CourseModel>>(
      stream: CourseService.coursesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load your courses.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final courses = snapshot.data ?? [];

        final filteredCourses = courses.where((course) {
          return course.code.toLowerCase().contains(_searchQuery) ||
              course.name.toLowerCase().contains(_searchQuery) ||
              course.lecturer.toLowerCase().contains(_searchQuery);
        }).toList();

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'My Courses',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your courses and academic progress.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (filteredCourses.isEmpty)
                  _EmptyCoursesState(
                    hasSearchQuery: _searchQuery.isNotEmpty,
                  )
                else
                  ...filteredCourses.map(
                    (course) => _CourseCard(
                      course: course,
                      icon: _courseIcon(course.code),
                      onEdit: () => _showCourseDialog(
                        context,
                        user.uid,
                        course: course,
                      ),
                      onDelete: () => _deleteCourse(
                        context,
                        user.uid,
                        course,
                      ),
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),

            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: () {
                  _showCourseDialog(
                    context,
                    user.uid,
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Course'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCourseDialog(
    BuildContext context,
    String userId, {
    CourseModel? course,
  }) async {
    final bool isEditing = course != null;

    final codeController = TextEditingController(
      text: course?.code ?? '',
    );

    final nameController = TextEditingController(
      text: course?.name ?? '',
    );

    final creditsController = TextEditingController(
      text: course?.credits.toString() ?? '3',
    );

    final lecturerController = TextEditingController(
      text: course?.lecturer ?? '',
    );

    final semesterController = TextEditingController(
      text: course?.semester.toString() ?? '4',
    );

    final progressController = TextEditingController(
      text: course != null
          ? (course.progress * 100).round().toString()
          : '0',
    );

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveCourse() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                final int credits =
                    int.parse(creditsController.text.trim());

                final int semester =
                    int.parse(semesterController.text.trim());

                final double progressPercentage =
                    double.parse(progressController.text.trim());

                final double progress =
                    progressPercentage / 100;

                if (isEditing) {
                  await CourseService.updateCourse(
                    userId: userId,
                    courseId: course.id,
                    code: codeController.text,
                    name: nameController.text,
                    credits: credits,
                    lecturer: lecturerController.text,
                    semester: semester,
                    progress: progress,
                  );
                } else {
                  await CourseService.addCourse(
                    userId: userId,
                    code: codeController.text,
                    name: nameController.text,
                    credits: credits,
                    lecturer: lecturerController.text,
                    semester: semester,
                    progress: progress,
                  );
                }

                if (!context.mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Course updated successfully.'
                          : 'Course added successfully.',
                    ),
                  ),
                );
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to save course: $e',
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Course' : 'Add Course',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: codeController,
                          textCapitalization:
                              TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Course Code',
                            hintText: 'e.g. CO2050',
                            prefixIcon:
                                Icon(Icons.code_rounded),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter the course code.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Course Name',
                            hintText: 'e.g. Database Systems',
                            prefixIcon:
                                Icon(Icons.book_rounded),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter the course name.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: creditsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Credits',
                            prefixIcon:
                                Icon(Icons.numbers_rounded),
                          ),
                          validator: (value) {
                            final credits =
                                int.tryParse(value ?? '');

                            if (credits == null ||
                                credits <= 0) {
                              return 'Enter valid credits.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: lecturerController,
                          decoration: const InputDecoration(
                            labelText: 'Lecturer',
                            hintText: 'e.g. Dr. A. Perera',
                            prefixIcon:
                                Icon(Icons.person_rounded),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter the lecturer name.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: semesterController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Semester',
                            prefixIcon:
                                Icon(Icons.calendar_month_rounded),
                          ),
                          validator: (value) {
                            final semester =
                                int.tryParse(value ?? '');

                            if (semester == null ||
                                semester <= 0) {
                              return 'Enter a valid semester.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: progressController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Progress (%)',
                            hintText: '0 - 100',
                            prefixIcon:
                                Icon(Icons.percent_rounded),
                          ),
                          validator: (value) {
                            final progress =
                                double.tryParse(value ?? '');

                            if (progress == null ||
                                progress < 0 ||
                                progress > 100) {
                              return 'Enter a value from 0 to 100.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : saveCourse,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Add Course',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
    nameController.dispose();
    creditsController.dispose();
    lecturerController.dispose();
    semesterController.dispose();
    progressController.dispose();
  }

  Future<void> _deleteCourse(
    BuildContext context,
    String userId,
    CourseModel course,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: Text(
            'Are you sure you want to delete ${course.code} - ${course.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await CourseService.deleteCourse(
        userId: userId,
        courseId: course.id,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete course: $e'),
        ),
      );
    }
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  final CourseModel course;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final percentage = (course.progress * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.code,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CourseInfo(
                  icon: Icons.school_outlined,
                  text: '${course.credits} Credits',
                ),
                const SizedBox(width: 16),
                if (course.lecturer.isNotEmpty)
                  Expanded(
                    child: _CourseInfo(
                      icon: Icons.person_outline,
                      text: course.lecturer,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Course Progress',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: course.progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseInfo extends StatelessWidget {
  const _CourseInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCoursesState extends StatelessWidget {
  const _EmptyCoursesState({
    required this.hasSearchQuery,
  });

  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              hasSearchQuery
                  ? Icons.search_off_rounded
                  : Icons.school_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              hasSearchQuery
                  ? 'No courses found'
                  : 'No courses yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearchQuery
                  ? 'Try a different search term.'
                  : 'Add your first course to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}