import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  const AuthException();
}

abstract interface class AuthService {
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  Stream<bool> get signedIn;
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({this._firebaseAuth});

  final FirebaseAuth? _firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  @override
  late final Stream<bool> signedIn = _auth.authStateChanges().map(
    (user) => user != null,
  );

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException {
      throw const AuthException();
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      throw const AuthException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException {
      throw const AuthException();
    }
  }
}
