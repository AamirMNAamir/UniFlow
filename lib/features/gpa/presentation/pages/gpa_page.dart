
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/gpa_course_model.dart';
import '../../data/gpa_course_service.dart';
import '../../data/semester_model.dart';
import '../../data/semester_service.dart';
import 'semester_details_page.dart';

class GpaPage extends StatefulWidget {
  const GpaPage({super.key});

  @override
  State<GpaPage> createState() => _GpaPageState();
}

class _GpaPageState extends State<GpaPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> _showAddSemesterDialog() async {
    final User? user = _user;

    if (user == null) {
      return;
    }

    final TextEditingController nameController =
        TextEditingController();

    final List<SemesterModel> semesters =
        await SemesterService.watchSemesters(user.uid).first;

    final int nextSemesterNumber = semesters.isEmpty
        ? 1
        : semesters
                .map(
                  (semester) => semester.semesterNumber,
                )
                .reduce(
                  (a, b) => a > b ? a : b,
                ) +
            1;

    nameController.text = 'Semester $nextSemesterNumber';

    if (!mounted) {
      nameController.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Semester'),
          content: TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Semester name',
              hintText: 'Semester 1',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final String name = nameController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                try {
                  await SemesterService.addSemester(
                    userId: user.uid,
                    name: name,
                    semesterNumber: nextSemesterNumber,
                  );

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.of(dialogContext).pop();

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$name added successfully.',
                      ),
                    ),
                  );
                } catch (error) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to add semester: $error',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _deleteSemester(
    SemesterModel semester,
  ) async {
    final User? user = _user;

    if (user == null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Semester?'),
          content: Text(
            'Are you sure you want to delete '
            '${semester.name} and all its courses?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await SemesterService.deleteSemester(
        userId: user.uid,
        semesterId: semester.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${semester.name} deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete semester: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _user;

    if (user == null) {
      return const Center(
        child: Text(
          'Please sign in to use the GPA Calculator.',
        ),
      );
    }

    return StreamBuilder<List<SemesterModel>>(
      stream: SemesterService.watchSemesters(user.uid),
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
                'Unable to load semesters.\n\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final List<SemesterModel> semesters = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildOverallGpaCard(
              user.uid,
              semesters,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Semesters',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _showAddSemesterDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Semester'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (semesters.isEmpty)
              _buildEmptyState()
            else
              ...semesters.map(
                (semester) => _buildSemesterCard(semester),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverallGpaCard(
    String userId,
    List<SemesterModel> semesters,
  ) {
    if (semesters.isEmpty) {
      return _overallCard(
        gpa: 0.0,
        semesterCount: 0,
      );
    }

    return StreamBuilder<List<GpaCourseModel>>(
      stream: _watchAllCourses(
        userId,
        semesters,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _overallCard(
            gpa: 0.0,
            semesterCount: semesters.length,
          );
        }

        final List<GpaCourseModel> courses =
            snapshot.data ?? [];

        final double overallGpa =
            GpaCourseService.calculateGpa(courses);

        return _overallCard(
          gpa: overallGpa,
          semesterCount: semesters.length,
        );
      },
    );
  }

  Stream<List<GpaCourseModel>> _watchAllCourses(
    String userId,
    List<SemesterModel> semesters,
  ) {
    if (semesters.isEmpty) {
      return Stream.value(
        const <GpaCourseModel>[],
      );
    }

    final List<Stream<List<GpaCourseModel>>> streams =
        semesters
            .map(
              (semester) => GpaCourseService.watchCourses(
                userId: userId,
                semesterId: semester.id,
              ),
            )
            .toList();

    return _combineCourseStreams(streams);
  }

  Stream<List<GpaCourseModel>> _combineCourseStreams(
    List<Stream<List<GpaCourseModel>>> streams,
  ) {
    return Stream.multi(
      (controller) {
        final List<List<GpaCourseModel>> values =
            List.generate(
          streams.length,
          (_) => const [],
        );

        final List<StreamSubscription<List<GpaCourseModel>>>
            subscriptions = [];

        for (int i = 0; i < streams.length; i++) {
          final int index = i;

          final StreamSubscription<List<GpaCourseModel>>
              subscription = streams[index].listen(
            (courses) {
              values[index] = courses;

              controller.add(
                values
                    .expand(
                      (courses) => courses,
                    )
                    .toList(),
              );
            },
            onError: controller.addError,
          );

          subscriptions.add(subscription);
        }

        controller.onCancel = () async {
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        };
      },
    );
  }

  Widget _overallCard({
    required double gpa,
    required int semesterCount,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.calculate_outlined,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Overall GPA',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              gpa.toStringAsFixed(2),
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$semesterCount '
              '${semesterCount == 1 ? 'semester' : 'semesters'} added',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterCard(
    SemesterModel semester,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SemesterDetailsPage(
                semester: semester,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: Text(
            '${semester.semesterNumber}',
          ),
        ),
        title: Text(
          semester.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Tap to add and manage courses',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chevron_right,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteSemester(semester);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.school_outlined,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'No semesters yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first semester to '
              'start calculating your GPA.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _showAddSemesterDialog,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add First Semester',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
