import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';

class _FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements FirebaseAuth {
  final List<({String email, String password})> signInCalls = [];
  final List<({String email, ActionCodeSettings? actionCodeSettings})>
  resetCalls = [];
  int signOutCalls = 0;
  final authStateController = StreamController<User?>();
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
  Future<void> signOut() async {
    signOutCalls += 1;
    final exception = exceptionToThrow;
    if (exception != null) {
      throw exception;
    }
  }

  @override
  Stream<User?> authStateChanges() => authStateController.stream;

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

  test('Given FirebaseAuth throws a FirebaseAuthException, when signInWithEmailAndPassword is called, then an AuthException is thrown', () async {
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
      throwsA(isA<AuthException>()),
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

  test('Given FirebaseAuth throws a FirebaseAuthException, when sendPasswordResetEmail is called, then an AuthException is thrown', () async {
    // Given
    final fakeAuth = _FakeFirebaseAuth()
      ..exceptionToThrow = FirebaseAuthException(code: 'invalid-email');
    final service = FirebaseAuthService(firebaseAuth: fakeAuth);

    // When, then
    await expectLater(
      service.sendPasswordResetEmail(email: 'not-an-email'),
      throwsA(isA<AuthException>()),
    );
  });

  test('Given FirebaseAuthService, when signOut is called, then the call is forwarded once', () async {
    // Given
    final fakeAuth = _FakeFirebaseAuth();
    final service = FirebaseAuthService(firebaseAuth: fakeAuth);

    // When
    await service.signOut();

    // Then
    expect(fakeAuth.signOutCalls, 1);
  });

  test('Given FirebaseAuth throws a FirebaseAuthException, when signOut is called, then an AuthException is thrown', () async {
    // Given
    final fakeAuth = _FakeFirebaseAuth()
      ..exceptionToThrow = FirebaseAuthException(
        code: 'network-request-failed',
      );
    final service = FirebaseAuthService(firebaseAuth: fakeAuth);

    // When, then
    await expectLater(service.signOut(), throwsA(isA<AuthException>()));
  });

  test('Given authStateChanges emits a user and then null, when signedIn is read, then the stream emits true then false', () async {
    // Given
    final fakeAuth = _FakeFirebaseAuth();
    final service = FirebaseAuthService(firebaseAuth: fakeAuth);
    final signedIn = service.signedIn;
    final events = <bool>[];
    final subscription = signedIn.listen(events.add);

    // When
    fakeAuth.authStateController.add(_FakeUser());
    fakeAuth.authStateController.add(null);
    await Future<void>.delayed(Duration.zero);

    // Then
    expect(service.signedIn, same(signedIn));
    expect(events, [true, false]);
    await subscription.cancel();
    await fakeAuth.authStateController.close();
  });
}
