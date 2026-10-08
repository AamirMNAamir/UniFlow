import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/assignment_model.dart';
import '../../data/assignment_service.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final User? user = _currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please sign in to view your assignments.'),
      );
    }

    return StreamBuilder<List<AssignmentModel>>(
      stream: AssignmentService.assignmentsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final assignments = snapshot.data ?? [];

        final filteredAssignments = assignments.where((assignment) {
          final matchesFilter = _selectedFilter == 'All' ||
              assignment.status.toLowerCase() ==
                  _selectedFilter.toLowerCase();

          final query = _searchQuery.trim().toLowerCase();

          final matchesSearch = query.isEmpty ||
              assignment.title.toLowerCase().contains(query) ||
              assignment.course.toLowerCase().contains(query) ||
              assignment.description.toLowerCase().contains(query);

          return matchesFilter && matchesSearch;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(assignments),
                _buildSearchBar(),
                _buildFilterBar(),
                Expanded(
                  child: filteredAssignments.isEmpty
                      ? _buildEmptyState(assignments.isEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            100,
                          ),
                          itemCount: filteredAssignments.length,
                          itemBuilder: (context, index) {
                            return _buildAssignmentCard(
                              filteredAssignments[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAssignmentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Assignment'),
          ),
        );
      },
    );
  }

  Widget _buildHeader(List<AssignmentModel> assignments) {
    final pendingCount = assignments
        .where(
          (assignment) =>
              assignment.status.toLowerCase() == 'pending',
        )
        .length;

    final completedCount = assignments
        .where(
          (assignment) =>
              assignment.status.toLowerCase() == 'completed',
        )
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assignments',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$pendingCount pending • $completedCount completed',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search assignments...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    const filters = [
      'All',
      'Pending',
      'Completed',
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            selectedColor: const Color(0xFF2563EB),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    final isCompleted =
        assignment.status.toLowerCase() == 'completed';

    final isOverdue = !isCompleted &&
        assignment.dueDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _toggleAssignmentStatus(assignment),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : Icons.assignment_outlined,
                      color: isCompleted
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? const Color(0xFF64748B)
                              : const Color(0xFF0F172A),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        assignment.course,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAssignmentDialog(
                        assignment: assignment,
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(assignment);
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
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (assignment.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                assignment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: isOverdue
                      ? Colors.red
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(assignment.dueDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOverdue
                        ? Colors.red
                        : const Color(0xFF64748B),
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 8),
                  _buildBadge(
                    'Overdue',
                    Colors.red,
                  ),
                ],
                const Spacer(),
                _buildPriorityBadge(
                  assignment.priority,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: assignment.progress.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor:
                          const Color(0xFFE2E8F0),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(assignment.progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _buildStatusBadge(
                  assignment.status,
                ),
                const Spacer(),
                if (!isCompleted)
                  TextButton.icon(
                    onPressed: () =>
                        _markAsCompleted(assignment),
                    icon: const Icon(
                      Icons.check,
                      size: 18,
                    ),
                    label: const Text('Complete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isCompleted =
        status.toLowerCase() == 'completed';

    return _buildBadge(
      status,
      isCompleted
          ? const Color(0xFF16A34A)
          : const Color(0xFF2563EB),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;

    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return _buildBadge(
      priority,
      color,
    );
  }

  Widget _buildBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noAssignments) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 52,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              noAssignments
                  ? 'No assignments yet'
                  : 'No matching assignments',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noAssignments
                  ? 'Create your first assignment to start tracking your academic tasks.'
                  : 'Try changing the filter or search query.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            if (noAssignments) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _showAssignmentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Assignment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load assignments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignmentDialog({
    AssignmentModel? assignment,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final titleController = TextEditingController(
      text: assignment?.title ?? '',
    );

    final courseController = TextEditingController(
      text: assignment?.course ?? '',
    );

    final descriptionController = TextEditingController(
      text: assignment?.description ?? '',
    );

    DateTime selectedDate =
        assignment?.dueDate ??
            DateTime.now().add(
              const Duration(days: 7),
            );

    String selectedStatus =
        assignment?.status ?? 'Pending';

    String selectedPriority =
        assignment?.priority ?? 'Medium';

    double selectedProgress =
        assignment?.progress ?? 0.0;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                assignment == null
                    ? 'Add Assignment'
                    : 'Edit Assignment',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Assignment Title',
                            prefixIcon:
                                Icon(Icons.assignment_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter a title.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: courseController,
                          decoration: const InputDecoration(
                            labelText: 'Course',
                            prefixIcon:
                                Icon(Icons.school_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter the course.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon:
                                Icon(Icons.description_outlined),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Due date
                        InkWell(
                          onTap: () async {
                            final date =
                                await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (date != null) {
                              setDialogState(() {
                                selectedDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  selectedDate.hour,
                                  selectedDate.minute,
                                );
                              });
                            }
                          },
                          borderRadius:
                              BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration:
                                const InputDecoration(
                              labelText: 'Due Date',
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _formatDate(selectedDate),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Status
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration:
                              const InputDecoration(
                            labelText: 'Status',
                            prefixIcon:
                                Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'Completed',
                              child: Text('Completed'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              selectedStatus = value;

                              if (value == 'Completed') {
                                selectedProgress = 1.0;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 14),

                        // Priority
                        DropdownButtonFormField<String>(
                          initialValue: selectedPriority,
                          decoration:
                              const InputDecoration(
                            labelText: 'Priority',
                            prefixIcon:
                                Icon(Icons.priority_high),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'High',
                              child: Text('High'),
                            ),
                            DropdownMenuItem(
                              value: 'Medium',
                              child: Text('Medium'),
                            ),
                            DropdownMenuItem(
                              value: 'Low',
                              child: Text('Low'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              selectedPriority = value;
                            });
                          },
                        ),

                        const SizedBox(height: 18),

                        // Progress
                        Row(
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(selectedProgress * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: selectedProgress,
                          min: 0,
                          max: 1,
                          divisions: 20,
                          onChanged: selectedStatus ==
                                  'Completed'
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedProgress =
                                        value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      if (assignment == null) {
                        await AssignmentService.addAssignment(
                          userId: user.uid,
                          title: titleController.text,
                          course: courseController.text,
                          description:
                              descriptionController.text,
                          dueDate: selectedDate,
                          status: selectedStatus,
                          priority: selectedPriority,
                          progress: selectedProgress,
                        );
                      } else {
                        await AssignmentService
                            .updateAssignment(
                          userId: user.uid,
                          assignmentId: assignment.id,
                          title: titleController.text,
                          course: courseController.text,
                          description:
                              descriptionController.text,
                          dueDate: selectedDate,
                          status: selectedStatus,
                          priority: selectedPriority,
                          progress: selectedProgress,
                        );
                      }

                      if (!dialogContext.mounted) return;

                      Navigator.pop(
                        dialogContext,
                        true,
                      );

                      if (!mounted) return;

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            assignment == null
                                ? 'Assignment added successfully.'
                                : 'Assignment updated successfully.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to save assignment: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    assignment == null ? 'Add' : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    courseController.dispose();
    descriptionController.dispose();

    if (result == true) {
      // Firestore stream updates the UI automatically.
    }
  }

  Future<void> _toggleAssignmentStatus(
    AssignmentModel assignment,
  ) async {
    final User? user = _currentUser;

    if (user == null) return;

    final isCompleted =
        assignment.status.toLowerCase() == 'completed';

    try {
      await AssignmentService.updateAssignment(
        userId: user.uid,
        assignmentId: assignment.id,
        title: assignment.title,
        course: assignment.course,
        description: assignment.description,
        dueDate: assignment.dueDate,
        status: isCompleted ? 'Pending' : 'Completed',
        priority: assignment.priority,
        progress: isCompleted ? assignment.progress : 1.0,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update assignment: $e',
          ),
        ),
      );
    }
  }

  Future<void> _markAsCompleted(
    AssignmentModel assignment,
  ) async {
    final User? user = _currentUser;

    if (user == null) return;

    try {
      await AssignmentService.updateAssignment(
        userId: user.uid,
        assignmentId: assignment.id,
        title: assignment.title,
        course: assignment.course,
        description: assignment.description,
        dueDate: assignment.dueDate,
        status: 'Completed',
        priority: assignment.priority,
        progress: 1.0,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Assignment marked as completed.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to complete assignment: $e',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    AssignmentModel assignment,
  ) async {
    final User? user = _currentUser;

    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Assignment'),
          content: Text(
            'Are you sure you want to delete "${assignment.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await AssignmentService.deleteAssignment(
        userId: user.uid,
        assignmentId: assignment.id,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Assignment deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete assignment: $e',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }
}