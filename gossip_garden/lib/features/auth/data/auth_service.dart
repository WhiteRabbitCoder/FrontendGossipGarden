import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'user_profile.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _googleSignIn = googleSignIn,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;
  final FirebaseFirestore? _firestore;

  Stream<User?> authStateChanges() =>
      _auth?.authStateChanges() ?? const Stream<User?>.empty();

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    if (_auth == null || _googleSignIn == null || _firestore == null) {
      throw StateError('Firebase no esta configurado.');
    }

    final auth = _auth!;
    final googleSignIn = _googleSignIn!;
    final firestore = _firestore!;

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'canceled',
        message: 'Inicio de sesion cancelado por el usuario.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await firestore.collection('users').doc(user.uid).set(
        {
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    return userCredential;
  }

  Future<UserProfile?> loadProfile(String uid) async {
    final firestore = _firestore;
    if (firestore == null) {
      return null;
    }

    final snapshot = await firestore.collection('users').doc(uid).get();
    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return UserProfile.fromJson(data);
  }

  Future<void> completeOnboarding(String uid) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }

    await firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> signOut() async {
    if (_googleSignIn == null || _auth == null) {
      return;
    }

    final googleSignIn = _googleSignIn!;
    final auth = _auth!;

    await googleSignIn.signOut();
    await auth.signOut();
  }
}
