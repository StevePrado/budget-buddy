import 'package:flutter/material.dart';
import 'constants/app_strings.dart';
import 'theme/app_theme.dart';
import 'widgets/main_shell.dart';

// Teammate note: Main BudgetBuddy application widget
class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const MainShell(),
    );
  }
}
