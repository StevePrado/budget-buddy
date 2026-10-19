import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'constants/app_strings.dart';
import 'screens/auth/auth_screen.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_screen.dart';

// Main BudgetBuddy application widget.
// Shows AuthScreen when signed out and HomeScreen (tabs) when signed in.
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}
