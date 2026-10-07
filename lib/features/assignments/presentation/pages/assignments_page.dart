import 'package:flutter/material.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _assignments = [
    {
      'title': 'Database Normalization',
      'course': 'CO2050',
      'dueDate': 'Oct 10, 2026',
      'status': 'Pending',
      'priority': 'High',
    },
    {
      'title': 'CPU Pipelining Report',
      'course': 'CO2070',
      'dueDate': 'Oct 12, 2026',
      'status': 'Pending',
      'priority': 'Medium',
    },
    {
      'title': 'Network Design Lab',
      'course': 'CO2080',
      'dueDate': 'Oct 05, 2026',
      'status': 'Completed',
      'priority': 'Low',
    },
    {
      'title': 'CNN Image Classification',
      'course': 'CO5420',
      'dueDate': 'Oct 15, 2026',
      'status': 'Pending',
      'priority': 'High',
    },
  ];

  List<Map<String, dynamic>> get _filteredAssignments {
    if (_selectedFilter == 'All') {
      return _assignments;
    }

    return _assignments
        .where((assignment) => assignment['status'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Assignments',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Stay on top of your academic tasks.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Filter buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Pending', 'Completed'].map((filter) {
              final isSelected = _selectedFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Assignment count
        Text(
          '${_filteredAssignments.length} assignment'
          '${_filteredAssignments.length == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 12),

        // Assignment cards
        ..._filteredAssignments.map(
          (assignment) => _AssignmentCard(
            title: assignment['title'],
            course: assignment['course'],
            dueDate: assignment['dueDate'],
            status: assignment['status'],
            priority: assignment['priority'],
            onStatusChanged: () {
              setState(() {
                assignment['status'] =
                    assignment['status'] == 'Completed'
                        ? 'Pending'
                        : 'Completed';
              });
            },
          ),
        ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.title,
    required this.course,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.onStatusChanged,
  });

  final String title;
  final String course;
  final String dueDate;
  final String status;
  final String priority;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'Completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion button
            IconButton(
              onPressed: onStatusChanged,
              icon: Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isCompleted
                    ? Colors.green
                    : const Color(0xFF2563EB),
                size: 28,
              ),
            ),

            const SizedBox(width: 4),

            // Assignment information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Due: $dueDate',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusBadge(
                        label: status,
                        isCompleted: isCompleted,
                      ),
                      const SizedBox(width: 8),
                      _PriorityBadge(priority: priority),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.isCompleted,
  });

  final String label;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({
    required this.priority,
  });

  final String priority;

  @override
  Widget build(BuildContext context) {
    final Color textColor;

    switch (priority) {
      case 'High':
        textColor = Colors.red.shade700;
        break;
      case 'Medium':
        textColor = Colors.orange.shade700;
        break;
      default:
        textColor = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}