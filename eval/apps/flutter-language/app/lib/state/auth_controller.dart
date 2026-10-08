import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_repository.dart';
import '../data/fake_backend.dart';
import '../data/models.dart';

enum AuthStatus { restoring, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  static const _sessionKey = 'parla.session';

  final AuthRepository _repository;
  AuthStatus _status = AuthStatus.restoring;
  Session? _session;

  AuthStatus get status => _status;
  Session? get session => _session;
  User? get user => _session?.user;
  String? get token => _session?.token;

  /// Restores the saved session on launch and refreshes the user from the API.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) {
      _set(null);
      return;
    }
    final saved = Session.fromJson((jsonDecode(raw) as Map).cast());
    try {
      final user = await _repository.me(saved.token);
      await _persist(Session(token: saved.token, user: user));
    } on ApiException catch (error) {
      if (error.code == 'network_error') {
        // Offline at launch: keep the cached session so the app stays usable.
        _set(saved);
      } else {
        await _persist(null);
      }
    }
  }

  Future<User> signUp({
    required String fullName,
    required String email,
    required String password,
    required bool marketingOptIn,
  }) async {
    final next = await _repository.signUp(
      fullName: fullName,
      email: email,
      password: password,
      marketingOptIn: marketingOptIn,
    );
    await _persist(next);
    return next.user;
  }

  Future<User> logIn(String email, String password) async {
    final next = await _repository.logIn(email, password);
    await _persist(next);
    return next.user;
  }

  Future<void> logOut() async {
    final token = _session?.token;
    await _persist(null);
    if (token == null) return;
    try {
      await _repository.logOut(token);
    } on ApiException {
      // The local session is gone either way.
    }
  }

  Future<User> completeOnboarding(OnboardingAnswers answers) async {
    final current = _session;
    if (current == null) throw StateError('Not signed in');
    final user = await _repository.saveOnboarding(current.token, answers);
    await _persist(Session(token: current.token, user: user));
    return user;
  }

  Future<void> _persist(Session? next) async {
    final prefs = await SharedPreferences.getInstance();
    if (next == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, jsonEncode(next.toJson()));
    }
    _set(next);
  }

  void _set(Session? next) {
    _session = next;
    _status = next == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }
}
