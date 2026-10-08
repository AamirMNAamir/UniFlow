import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/calendar_service.dart';

class ImportCalendarPage extends StatefulWidget {
  const ImportCalendarPage({super.key});

  @override
  State<ImportCalendarPage> createState() =>
      _ImportCalendarPageState();
}

class _ImportCalendarPageState
    extends State<ImportCalendarPage> {
  final _formKey = GlobalKey<FormState>();

  final _urlController = TextEditingController();

  bool _automaticSync = true;

  bool _importAssignments = true;
  bool _importQuizzes = true;
  bool _importOtherActivities = true;

  bool _isSaving = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 20),
                _buildUrlSection(),
                const SizedBox(height: 20),
                _buildImportOptions(),
                const SizedBox(height: 20),
                _buildSecurityNotice(),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed:
                        _isSaving ? null : _importCalendar,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_download),
                    label: Text(
                      _isSaving
                          ? 'Connecting...'
                          : 'Import Calendar',
                    ),
                  ),
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(20),
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
            'Connect your university calendar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'UniFlow can automatically organize your '
            'assignments, quizzes, exams and other '
            'academic activities.',
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

  Widget _buildUrlSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendar URL',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Paste the iCalendar URL provided by FEELS/Moodle.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _urlController,
              keyboardType:
                  TextInputType.url,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'https://feels.pdn.ac.lk/...',
                prefixIcon:
                    Icon(Icons.link),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final url =
                    value?.trim() ?? '';

                if (url.isEmpty) {
                  return 'Please enter your calendar URL.';
                }

                final uri = Uri.tryParse(url);

                if (uri == null ||
                    !uri.hasScheme ||
                    !uri.hasAuthority) {
                  return 'Please enter a valid calendar URL.';
                }

                return null;
              },
            ),
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
        borderRadius: BorderRadius.circular(18),
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
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Automatic synchronization',
              ),
              subtitle: const Text(
                'Keep your UniFlow calendar updated automatically.',
              ),
              value: _automaticSync,
              onChanged: (value) {
                setState(() {
                  _automaticSync = value;
                });
              },
            ),
            const Divider(),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Assignments'),
              value: _importAssignments,
              onChanged: (value) {
                setState(() {
                  _importAssignments =
                      value ?? true;
                });
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quizzes'),
              value: _importQuizzes,
              onChanged: (value) {
                setState(() {
                  _importQuizzes =
                      value ?? true;
                });
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Other activities',
              ),
              value: _importOtherActivities,
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

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFED7AA),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security_outlined,
            color: Color(0xFFEA580C),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your calendar URL may contain a private '
              'authentication token. UniFlow will handle '
              'the connection securely through the backend. '
              'Do not share your calendar URL with others.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9A3412),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importCalendar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      /*
       * IMPORTANT:
       *
       * At this stage we only register the calendar
       * source in Firestore.
       *
       * The actual FEELS URL will NOT be stored here.
       *
       * In the next stage, Firebase Cloud Functions
       * will securely store/use the URL and download
       * the iCalendar feed.
       */

      await CalendarService.createCalendarSource(
        userId: user.uid,
        name: 'FEELS Calendar',
        type: 'moodle',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Calendar source connected. Automatic import will be enabled in the next step.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to connect calendar: $e',
          ),
        ),
      );
    }
  }
}