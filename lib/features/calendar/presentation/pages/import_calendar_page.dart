import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/calendar_ics_parser.dart';
import '../../data/calendar_service.dart';
import '../../data/calendar_event_model.dart';

class ImportCalendarPage extends StatefulWidget {
  const ImportCalendarPage({super.key});

  @override
  State<ImportCalendarPage> createState() =>
      _ImportCalendarPageState();
}

class _ImportCalendarPageState
    extends State<ImportCalendarPage> {
  bool _importAssignments = true;
  bool _importQuizzes = true;
  bool _importOtherActivities = true;

  bool _isImporting = false;

  PlatformFile? _selectedFile;

  List<CalendarEventModel> _previewEvents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Import Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 20),
              _buildFilePickerCard(),
              const SizedBox(height: 20),
              _buildImportOptions(),
              const SizedBox(height: 20),
              _buildHowItWorks(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _isImporting ? null : _importCalendar,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.upload_file,
                        ),
                  label: Text(
                    _isImporting
                        ? 'Importing...'
                        : 'Import Calendar',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.calendar_month,
            color: Colors.white,
            size: 36,
          ),
          SizedBox(height: 14),
          Text(
            'Import your university calendar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Download your FEELS/Moodle calendar '
            'as an .ics file and import it into UniFlow. '
            'Your academic events can then appear in '
            'your UniFlow calendar and Tasks.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'FEELS Calendar File',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select the .ics calendar file downloaded '
              'from FEELS/Moodle.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFF8FAFC),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color:
                      const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile == null
                        ? Icons
                            .insert_drive_file_outlined
                        : Icons
                            .check_circle_outline,
                    size: 42,
                    color: _selectedFile == null
                        ? const Color(
                            0xFF64748B,
                          )
                        : const Color(
                            0xFF16A34A,
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedFile == null
                        ? 'No calendar file selected'
                        : _selectedFile!.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed:
                        _isImporting
                            ? null
                            : _pickCalendarFile,
                    icon: const Icon(
                      Icons.folder_open,
                    ),
                    label: Text(
                      _selectedFile == null
                          ? 'Select .ics File'
                          : 'Choose Another File',
                    ),
                  ),
                ],
              ),
            ),
            if (_previewEvents.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEFF6FF),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      color:
                          Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_previewEvents.length} '
                        'calendar events detected',
                        style: const TextStyle(
                          color:
                              Color(0xFF1E40AF),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptions() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Import options',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose which types of events should be '
              'imported.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: const Text(
                'Assignments',
              ),
              subtitle: const Text(
                'Add assignment events to Tasks.',
              ),
              value: _importAssignments,
              onChanged: (value) {
                setState(() {
                  _importAssignments =
                      value ?? true;
                });
              },
            ),
            CheckboxListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: const Text(
                'Quizzes',
              ),
              subtitle: const Text(
                'Import quiz events into Calendar.',
              ),
              value: _importQuizzes,
              onChanged: (value) {
                setState(() {
                  _importQuizzes =
                      value ?? true;
                });
              },
            ),
            CheckboxListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: const Text(
                'Other activities',
              ),
              subtitle: const Text(
                'Import lectures, labs, exams and '
                'other events.',
              ),
              value:
                  _importOtherActivities,
              onChanged: (value) {
                setState(() {
                  _importOtherActivities =
                      value ?? true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security_outlined,
            color: Color(0xFF16A34A),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your calendar file is processed locally '
              'by UniFlow. No FEELS calendar URL or '
              'authentication token is stored by the app.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF166534),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCalendarFile() async {
    try {
      final PlatformFile? file =
          await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );

      if (file == null) {
        return;
      }

      final bytes =
          await file.readAsBytes();

      final String content =
          utf8.decode(bytes);

      final events =
          CalendarIcsParser.parse(content);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedFile = file;
        _previewEvents = events;
      });

      if (events.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'No calendar events were found in this file.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not read the calendar file: $e',
          ),
          duration:
              const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _importCalendar() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an .ics calendar file first.',
          ),
        ),
      );

      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in before importing your calendar.',
          ),
        ),
      );

      return;
    }

    if (_previewEvents.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No calendar events are available to import.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final List<CalendarEventModel>
          eventsToImport = [];

      for (final event in _previewEvents) {
        if (event.type == 'Assignment') {
          if (_importAssignments) {
            eventsToImport.add(event);
          }
        } else if (event.type == 'Quiz') {
          if (_importQuizzes) {
            eventsToImport.add(event);
          }
        } else {
          if (_importOtherActivities) {
            eventsToImport.add(event);
          }
        }
      }

      if (eventsToImport.isEmpty) {
        throw Exception(
          'No events match your selected import options.',
        );
      }

      final result =
          await CalendarService.importEvents(
        userId: user.uid,
        events: eventsToImport,
        importAssignments:
            _importAssignments,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isImporting = false;
      });

      final int importedEvents =
          result['events'] ?? 0;

      final int importedAssignments =
          result['assignments'] ?? 0;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Calendar imported successfully.\n'
            '$importedEvents events • '
            '$importedAssignments assignments added to Tasks.',
          ),
          duration:
              const Duration(seconds: 6),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isImporting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Calendar import failed: $e',
          ),
          duration:
              const Duration(seconds: 7),
        ),
      );
    }
  }
}