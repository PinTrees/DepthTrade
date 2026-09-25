import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// 게스트 (익명) 로그인 - 웹에서 바로 시작 가능
  Future<UserCredential?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      return cred;
    } catch (e) {
      debugPrint('Anonymous auth error: $e');
      return null;
    }
  }

  /// 이메일 / 비밀번호 로그인
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return cred;
    } catch (e) {
      debugPrint('Email auth error: $e');
      rethrow;
    }
  }

  /// 회원가입
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return cred;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
