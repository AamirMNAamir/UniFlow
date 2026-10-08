import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/gpa_course_model.dart';
import '../../data/gpa_course_service.dart';
import '../../data/semester_model.dart';

class SemesterDetailsPage extends StatefulWidget {
  const SemesterDetailsPage({
    super.key,
    required this.semester,
  });

  final SemesterModel semester;

  @override
  State<SemesterDetailsPage> createState() =>
      _SemesterDetailsPageState();
}

class _SemesterDetailsPageState
    extends State<SemesterDetailsPage> {
  final User? _user =
      FirebaseAuth.instance.currentUser;

  static const List<String> _grades = [
    'A+',
    'A',
    'A-',
    'B+',
    'B',
    'B-',
    'C+',
    'C',
    'C-',
    'D+',
    'D',
    'D-',
    'F',
  ];

  Future<void> _showCourseDialog({
    GpaCourseModel? course,
  }) async {
    final User? user = _user;

    if (user == null) {
      return;
    }

    final TextEditingController nameController =
        TextEditingController(
      text: course?.courseName ?? '',
    );

    final TextEditingController creditsController =
        TextEditingController(
      text: course?.credits.toString() ?? '',
    );

    String selectedGrade =
        course?.grade ?? 'A';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                course == null
                    ? 'Add Course'
                    : 'Edit Course',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration:
                          const InputDecoration(
                        labelText: 'Course Name',
                        hintText:
                            'e.g. Data Structures',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: creditsController,
                      keyboardType:
                          TextInputType.number,
                      decoration:
                          const InputDecoration(
                        labelText: 'Credits',
                        hintText: 'e.g. 3',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedGrade,
                      decoration:
                          const InputDecoration(
                        labelText: 'Grade',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: _grades
                          .map(
                            (grade) =>
                                DropdownMenuItem<
                                    String>(
                              value: grade,
                              child: Text(
                                grade,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedGrade =
                              value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        'Grade Point: '
                        '${GpaCourseService.gradePoints[selectedGrade]!.toStringAsFixed(1)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final String name =
                        nameController.text
                            .trim();

                    final int? credits =
                        int.tryParse(
                      creditsController.text
                          .trim(),
                    );

                    if (name.isEmpty ||
                        credits == null ||
                        credits <= 0) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid course name and credits.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      if (course == null) {
                        await GpaCourseService
                            .addCourse(
                          userId: user.uid,
                          semesterId:
                              widget.semester.id,
                          courseName: name,
                          credits: credits,
                          grade:
                              selectedGrade,
                        );
                      } else {
                        await GpaCourseService
                            .updateCourse(
                          userId: user.uid,
                          semesterId:
                              widget.semester.id,
                          courseId: course.id,
                          courseName: name,
                          credits: credits,
                          grade:
                              selectedGrade,
                        );
                      }

                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      Navigator.of(
                        dialogContext,
                      ).pop();
                    } catch (error) {
                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to save course: '
                            '$error',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    course == null
                        ? 'Add'
                        : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    creditsController.dispose();
  }

  Future<void> _deleteCourse(
    GpaCourseModel course,
  ) async {
    final User? user = _user;

    if (user == null) {
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Delete Course?'),
          content: Text(
            'Are you sure you want to delete '
            '${course.courseName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false);
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await GpaCourseService.deleteCourse(
        userId: user.uid,
        semesterId: widget.semester.id,
        courseId: course.id,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete course: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.semester.name,
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            _showCourseDialog(),
        icon: const Icon(Icons.add),
        label:
            const Text('Add Course'),
      ),
      body: StreamBuilder<
          List<GpaCourseModel>>(
        stream:
            GpaCourseService.watchCourses(
          userId: user.uid,
          semesterId:
              widget.semester.id,
        ),
        builder:
            (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  'Unable to load courses.\n\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final List<GpaCourseModel>
              courses =
              snapshot.data ?? [];

          final double semesterGpa =
              GpaCourseService
                  .calculateGpa(
            courses,
          );

          final int totalCredits =
              GpaCourseService
                  .calculateTotalCredits(
            courses,
          );

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              100,
            ),
            children: [
              _buildSummaryCard(
                semesterGpa,
                totalCredits,
                courses.length,
              ),
              const SizedBox(height: 20),
              Text(
                'Courses',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (courses.isEmpty)
                _buildEmptyState()
              else
                ...courses.map(
                  (course) =>
                      _buildCourseCard(
                    course,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    double gpa,
    int credits,
    int courseCount,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.calculate_outlined,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Semester GPA',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              gpa.toStringAsFixed(2),
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              '$courseCount '
              '${courseCount == 1 ? 'course' : 'courses'}'
              ' • $credits credits',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    GpaCourseModel course,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: Text(
            course.grade,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          course.courseName,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${course.credits} Credits • '
          'Grade Point: '
          '${course.gradePoint.toStringAsFixed(1)}',
        ),
        trailing:
            PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showCourseDialog(
                course: course,
              );
            } else if (value ==
                'delete') {
              _deleteCourse(course);
            }
          },
          itemBuilder: (context) =>
              const [
            PopupMenuItem<String>(
              value: 'edit',
              child: Text('Edit'),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your courses to calculate '
              'your semester GPA.',
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  _showCourseDialog,
              icon:
                  const Icon(Icons.add),
              label:
                  const Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }
}