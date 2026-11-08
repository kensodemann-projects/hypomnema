import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({this.firebaseAuth});

  final FirebaseAuth? firebaseAuth;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
