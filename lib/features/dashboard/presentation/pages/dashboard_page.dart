
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to continue.'),
        ),
      );
    }

    final String userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UniFlow',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (userSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load dashboard data.'),
            );
          }

          final Map<String, dynamic> userData =
              userSnapshot.data?.data() ?? {};

          final String name =
              (userData['name'] as String?)?.trim().isNotEmpty == true
                  ? (userData['name'] as String).trim()
                  : 'Student';

          final double gpa = _toDouble(userData['currentGpa']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, $name 👋',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your academic life, simplified.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 28),

                _StatCard(
                  title: 'Current GPA',
                  value: gpa.toStringAsFixed(2),
                  icon: Icons.school_outlined,
                ),

                const SizedBox(height: 16),

                const _StatCard(
                  title: 'Attendance',
                  value: '87%',
                  icon: Icons.event_available_outlined,
                ),

                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('assignments')
                      .where('status', isEqualTo: 'Pending')
                      .snapshots(),
                  builder: (context, assignmentSnapshot) {
                    if (assignmentSnapshot.hasError) {
                      return const _StatCard(
                        title: 'Pending Assignments',
                        value: '--',
                        icon: Icons.assignment_outlined,
                      );
                    }

                    final int pendingCount =
                        assignmentSnapshot.data?.docs.length ?? 0;

                    return _StatCard(
                      title: 'Pending Assignments',
                      value: pendingCount.toString(),
                      icon: Icons.assignment_outlined,
                    );
                  },
                ),

                const SizedBox(height: 32),

                const Text(
                  "Today's Classes",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _TodayClasses(
                  userId: userId,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

class _TodayClasses extends StatelessWidget {
  final String userId;

  const _TodayClasses({
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    final DateTime startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calendar_events')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'startTime',
            isLessThan: Timestamp.fromDate(endOfDay),
          )
          .orderBy('startTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Unable to load today\'s classes.',
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No classes or calendar events scheduled for today.',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final Map<String, dynamic> data = doc.data();

            final String title =
                (data['title'] as String?)?.trim().isNotEmpty == true
                    ? (data['title'] as String).trim()
                    : 'Untitled event';

            final String course =
                (data['course'] as String?)?.trim() ?? '';

            final DateTime? startTime =
                _timestampToDateTime(data['startTime']);

            final String time = startTime == null
                ? '--'
                : _formatTime(startTime);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClassCard(
                course: title,
                code: course.isEmpty ? 'Calendar Event' : course,
                time: time,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  static String _formatTime(DateTime dateTime) {
    final int hour = dateTime.hour;
    final int minute = dateTime.minute;

    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String course;
  final String code;
  final String time;

  const _ClassCard({
    required this.course,
    required this.code,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.1),
          child: Icon(
            Icons.book_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          course,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(code),
        trailing: Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
