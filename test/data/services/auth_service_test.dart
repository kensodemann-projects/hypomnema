import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/data/services/auth_service.dart';

class _FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements FirebaseAuth {
  final List<({String email, String password})> signInCalls = [];
  final List<({String email, ActionCodeSettings? actionCodeSettings})>
  resetCalls = [];
  FirebaseAuthException? exceptionToThrow;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls.add((email: email, password: password));
    final exception = exceptionToThrow;
    if (exception != null) {
      throw exception;
    }
    return _FakeUserCredential();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetCalls.add((email: email, actionCodeSettings: actionCodeSettings));
    final exception = exceptionToThrow;
    if (exception != null) {
      throw exception;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Given FirebaseAuthService, when signInWithEmailAndPassword is called for two accounts, then each call is forwarded in order', () async {
    // Given
    final fakeAuth = _FakeFirebaseAuth();
    final service = FirebaseAuthService(firebaseAuth: fakeAuth);

    // When
    await service.signInWithEmailAndPassword(
      email: 'first@example.com',
      password: 'password-one',
    );
    await service.signInWithEmailAndPassword(
      email: 'second@example.com',
      password: 'password-two',
    );

    // Then
    expect(fakeAuth.signInCalls, [
      (email: 'first@example.com', password: 'password-one'),
      (email: 'second@example.com', password: 'password-two'),
    ]);
  });

  test('Given FirebaseAuth throws a FirebaseAuthException, when signInWithEmailAndPassword is called, then the exception propagates with its code', () async {
    // Given
    final fakeAuth = _FakeFirebaseAuth()
      ..exceptionToThrow = FirebaseAuthException(code: 'invalid-credential');
    final service = FirebaseAuthService(firebaseAuth: fakeAuth);

    // When, then
    await expectLater(
      service.signInWithEmailAndPassword(
        email: 'person@example.com',
        password: 'wrong-password',
      ),
      throwsA(
        isA<FirebaseAuthException>().having(
          (exception) => exception.code,
          'code',
          'invalid-credential',
        ),
      ),
    );
  });

  test('Given FirebaseAuthService, when sendPasswordResetEmail is called, then the email is forwarded without action code settings', () async {
    // Given
    final fakeAuth = _FakeFirebaseAuth();
    final service = FirebaseAuthService(firebaseAuth: fakeAuth);

    // When
    await service.sendPasswordResetEmail(email: 'person@example.com');

    // Then
    expect(fakeAuth.resetCalls, [
      (email: 'person@example.com', actionCodeSettings: null),
    ]);
  });

  test('Given FirebaseAuth throws a FirebaseAuthException, when sendPasswordResetEmail is called, then the exception propagates with its code', () async {
    // Given
    final fakeAuth = _FakeFirebaseAuth()
      ..exceptionToThrow = FirebaseAuthException(code: 'invalid-email');
    final service = FirebaseAuthService(firebaseAuth: fakeAuth);

    // When, then
    await expectLater(
      service.sendPasswordResetEmail(email: 'not-an-email'),
      throwsA(
        isA<FirebaseAuthException>().having(
          (exception) => exception.code,
          'code',
          'invalid-email',
        ),
      ),
    );
  });
}
