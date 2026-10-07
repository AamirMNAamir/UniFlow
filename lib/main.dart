import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_shell.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const UniFlowApp());
}

class UniFlowApp extends StatelessWidget {
  const UniFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}