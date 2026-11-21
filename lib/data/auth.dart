import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mzumbefood/core/strings.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });
}

class AuthResult {
  final bool ok;
  final String? message;

  const AuthResult({required this.ok, this.message});

  factory AuthResult.success() => const AuthResult(ok: true);
  factory AuthResult.failure(String message) =>
      AuthResult(ok: false, message: message);
}

abstract class AuthService {
  Stream<AppUser?> get authState;
  AppUser? get currentUser;

  Future<AuthResult> signIn(String email, String password);

  Future<AuthResult> signUp(
    String email,
    String password,
    String ownerName,
    String businessName,
  );

  Future<AuthResult> sendPasswordReset(String email);

  Future<AuthResult> changePassword(
    String email,
    String currentPassword,
    String newPassword,
  );

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService(this._auth);

  @override
  Stream<AppUser?> get authState => _auth.authStateChanges().map((user) =>
      user == null
          ? null
          : AppUser(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? '',
            ));

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  @override
  Future<AuthResult> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_friendly(error));
    } catch (_) {
      return AuthResult.failure(S.genericError);
    }
  }

  @override
  Future<AuthResult> signUp(
    String email,
    String password,
    String ownerName,
    String businessName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(ownerName.trim());
      return AuthResult.success();
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_friendly(error));
    } catch (_) {
      return AuthResult.failure(S.genericError);
    }
  }

  @override
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success();
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_friendly(error));
    } catch (_) {
      return AuthResult.failure(S.genericError);
    }
  }

  @override
  Future<AuthResult> changePassword(
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return AuthResult.failure(S.genericError);
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return AuthResult.success();
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_friendly(error));
    } catch (_) {
      return AuthResult.failure(S.genericError);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _friendly(FirebaseAuthException error) => switch (error.code) {
        'wrong-password' || 'invalid-credential' => S.wrongPassword,
        'user-not-found' => S.userNotFound,
        'email-already-in-use' => S.emailInUse,
        'weak-password' => S.weakPassword,
        'invalid-email' => 'Please enter a valid email address.',
        'network-request-failed' => S.noInternet,
        'too-many-requests' => 'Too many attempts. Please wait a moment.',
        'requires-recent-login' => 'Please sign in again to change your password.',
        _ => error.message ?? S.genericError,
      };
}

class FakeAuthService implements AuthService {
  final Duration initialDelay;
  AppUser? _user;
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  FakeAuthService({this.initialDelay = Duration.zero, this._user});

  @override
  Stream<AppUser?> get authState => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  void emit(AppUser? user) {
    _user = user;
    if (initialDelay == Duration.zero) {
      _controller.add(user);
    } else {
      Future<void>.delayed(initialDelay, () => _controller.add(user));
    }
  }

  @override
  Future<AuthResult> signIn(String email, String password) async {
    if (password.length < 6) return AuthResult.failure(S.wrongPassword);
    emit(AppUser(
      uid: 'test-uid',
      email: email.trim(),
      displayName: 'Test Owner',
    ));
    return AuthResult.success();
  }

  @override
  Future<AuthResult> signUp(
    String email,
    String password,
    String ownerName,
    String businessName,
  ) async {
    if (password.length < 6) return AuthResult.failure(S.weakPassword);
    emit(AppUser(
      uid: 'test-uid',
      email: email.trim(),
      displayName: ownerName,
    ));
    return AuthResult.success();
  }

  @override
  Future<AuthResult> sendPasswordReset(String email) async =>
      AuthResult.success();

  @override
  Future<AuthResult> changePassword(
    String email,
    String currentPassword,
    String newPassword,
  ) async =>
      AuthResult.success();

  @override
  Future<void> signOut() async => emit(null);

  void dispose() => _controller.close();
}
