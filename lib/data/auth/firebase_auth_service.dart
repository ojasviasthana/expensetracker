import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Uses native Firebase Auth Web Popup (Bypasses google_sign_in package constructor error)
        final googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Fallback for iOS/Android
        // NOTE: Full iOS integration usually requires the google_sign_in package.
        // Using anonymous for now if triggered on native to prevent crash.
        print('Native Google Sign in requires external plugin. Signing in anonymously for testing.');
        return await _auth.signInAnonymously();
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
