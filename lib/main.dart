import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'constants/app_strings.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'widgets/main_shell.dart';

// Firebase teammate: add `await Firebase.initializeApp(...)` in main()
// and swap `home:` for an auth gate (login screen if signed out, MainShell if signed in).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BudgetBuddyApp());
}

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
