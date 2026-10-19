import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Register with email and password
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // Login with email and password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Friendly error message from FirebaseAuthException
  String getFriendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few moments and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'channel-error':
        return 'Please fill in both email and password fields.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}
