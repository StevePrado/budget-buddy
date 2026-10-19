import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Shows a confirmation dialog, then signs the user out.
// app.dart's authStateChanges listener swaps in the AuthScreen afterwards.
Future<void> confirmAndLogout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  if (shouldLogout == true) {
    await FirebaseAuth.instance.signOut();
  }
}
