import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

abstract class AuthenticationDatasource {
  Future<void> register(String email, String password, String passwordConfirm, BuildContext context);
  Future<void> login(String email, String password, BuildContext context);
}

class AuthenticationRemote extends AuthenticationDatasource {
  @override
  Future<void> login(String email, String password, BuildContext context) async {
    // Capture messenger before any await to avoid using BuildContext across async gaps
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Navigation happens automatically via StreamBuilder in main.dart
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else {
        message = 'Login failed: ${e.message}';
      }
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Sign in (or register) with Google via Firebase
  Future<void> signInWithGoogle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Google sign-in cancelled')));
        return;
      }

      // Obtain authentication; defensive handling for platform/channel shape issues.
      final googleAuth = await googleUser.authentication;

      // Helper to normalize token values that might unexpectedly be List or Map due to platform/channel issues.
      String? normalizeToken(dynamic raw) {
        if (raw == null) return null;
        try {
          if (raw is String) return raw;
          if (raw is List) {
            // join elements if it's a list of strings
            return raw.map((e) => e?.toString() ?? '').join('');
          }
          if (raw is Map) {
            // try common keys
            if (raw.containsKey('idToken')) return raw['idToken']?.toString();
            if (raw.containsKey('token')) return raw['token']?.toString();
            // fallback to stringifying the map
            return raw.values.map((e) => e?.toString() ?? '').join('');
          }
          // fallback
          return raw.toString();
        } catch (e) {
          developer.log('normalizeToken error: $e', name: 'auth.signInWithGoogle');
          return raw.toString();
        }
      }

      // normalize both tokens
      final dynamic rawId = (googleAuth as dynamic).idToken;
      final dynamic rawAccess = (googleAuth as dynamic).accessToken;
      final idToken = normalizeToken(rawId);
      final accessToken = normalizeToken(rawAccess);

      developer.log('Google auth tokens normalized: idToken=${idToken != null ? '<present>' : '<null>'}, accessToken=${accessToken != null ? '<present>' : '<null>'}', name: 'auth.signInWithGoogle');

      if (idToken == null && accessToken == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Google sign-in returned no tokens. Try again or use another sign-in method.')));
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      // On success navigation/stream in main will handle UI transitions.
    } on FirebaseAuthException catch (e) {
      developer.log('FirebaseAuthException during Google sign-in: ${e.code} ${e.message}', name: 'auth.signInWithGoogle');
      messenger.showSnackBar(SnackBar(content: Text('Google sign-in failed: ${e.message}')));
    } catch (e, st) {
      // Catch unexpected "pigeon" / platform/channel errors and show helpful guidance
      developer.log('Google sign-in unexpected error: $e\n$st', name: 'auth.signInWithGoogle');
      final msg = e.toString().contains('Unexpected') || e.toString().contains('pigeon')
          ? 'Platform sign-in error (channel type mismatch). Try upgrading/downgrading google_sign_in plugin or use another sign-in method.'
          : 'Google sign-in error: $e';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Future<void> register(
    String email,
    String password,
    String passwordConfirm,
    BuildContext context,
  ) async {
    // Capture messenger and navigator before any await to avoid using BuildContext across async gaps
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    // Validate password match
    if (passwordConfirm != password) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate password length
    if (password.length < 6) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 6 characters long.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Show a modal loading indicator while creating the user to avoid UI jank
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Use the returned UID instead of relying on currentUser immediately
      final uid = credential.user?.uid;

      // Dismiss loading indicator on success
      try {
        navigator.pop();
      } catch (_) {}
      // Navigation happens automatically via StreamBuilder in main.dart
    } on FirebaseAuthException catch (e) {
      // Ensure loading dialog is dismissed
      try {
        navigator.pop();
      } catch (_) {}
      String message = 'Registration failed';
      if (e.code == 'weak-password') {
        message = 'Password is too weak. Use a stronger password.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'network-request-failed' || (e.message?.toLowerCase().contains('recaptcha') ?? false)) {
        // Network / reCAPTCHA-specific guidance on emulator vs real device
        message = 'Network error during reCAPTCHA/verification. If you are using an emulator, try using a Google Play system image or test on a real device. For local testing, consider using the Firebase Auth emulator (`--dart-define=USE_FIREBASE_EMULATOR=true`).';
      } else {
        message = 'Registration failed: ${e.message}';
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Ensure loading dialog is dismissed
      try {
        navigator.pop();
      } catch (_) {}

      messenger.showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
