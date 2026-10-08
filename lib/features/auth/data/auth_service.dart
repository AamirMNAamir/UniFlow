import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Currently signed-in user.
  static User? get currentUser => _auth.currentUser;

  /// Stream that reports authentication state changes.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with email and password,
  /// then create their Firestore student profile.
  static Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Unable to create the user account.',
      );
    }

    await user.updateDisplayName(name.trim());

    await _firestore.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'studentId': '',
      'department': 'Computer Engineering',
      'university': 'University of Peradeniya',
      'currentGpa': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  /// Sign in an existing user.
  ///
  /// If the Firebase Auth account already exists but its
  /// Firestore profile does not, create the profile automatically.
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential =
        await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;

    if (user == null) {
      return credential;
    }

    final DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection('users').doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'name': user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'UniFlow Student',
        'email': user.email ?? email.trim(),
        'studentId': '',
        'department': 'Computer Engineering',
        'university': 'University of Peradeniya',
        'currentGpa': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  /// Sign out the current user.
  static Future<void> signOut() {
    return _auth.signOut();
  }
}