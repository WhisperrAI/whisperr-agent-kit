import 'fake_backend.dart';
import 'fixtures.dart';
import 'models.dart';

class AuthRepository {
  AuthRepository(this._backend);

  final FakeBackend _backend;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<Session> signUp({
    required String fullName,
    required String email,
    required String password,
    required bool marketingOptIn,
  }) {
    return _backend.request(() {
      final normalized = email.trim().toLowerCase();
      if (fullName.trim().isEmpty) {
        throw const ApiException('validation_error', 'Tell us your name.');
      }
      if (!_emailPattern.hasMatch(normalized)) {
        throw const ApiException('validation_error', 'Enter a valid email address.');
      }
      if (password.length < 8) {
        throw const ApiException('validation_error', 'Use at least 8 characters for your password.');
      }
      final accounts = _backend.table('accounts');
      if (takenEmails.contains(normalized) || accounts.containsKey(normalized)) {
        throw const ApiException('email_taken', 'An account with this email already exists. Log in instead.',
            status: 409);
      }
      final user = User(
        id: FakeBackend.userIdForEmail(normalized),
        email: normalized,
        fullName: fullName.trim(),
        phone: demoProfiles[normalized]?.phone,
        marketingOptIn: marketingOptIn,
        onboarded: false,
        createdAt: DateTime.now().toUtc(),
      );
      accounts[normalized] = {'password': password, 'user': user.toJson()};
      return _openSession(user);
    });
  }

  Future<Session> logIn(String email, String password) {
    return _backend.request(() {
      final account = _backend.table('accounts')[email.trim().toLowerCase()] as Map?;
      if (account == null || account['password'] != password) {
        throw const ApiException('invalid_credentials', 'That email and password do not match.', status: 401);
      }
      return _openSession(User.fromJson((account['user']! as Map).cast()));
    });
  }

  Future<User> me(String token) => _backend.request(() => _userFor(token));

  Future<void> logOut(String token) => _backend.request(() {
        _backend.table('sessions').remove(token);
      });

  Future<User> saveOnboarding(String token, OnboardingAnswers answers) {
    return _backend.request(() {
      final user = _userFor(token).copyWith(
        onboarded: true,
        reason: answers.reason,
        level: answers.level,
        dailyGoalMinutes: answers.dailyGoalMinutes,
      );
      (_backend.table('accounts')[user.email]! as Map)['user'] = user.toJson();
      return user;
    });
  }

  Session _openSession(User user) {
    final token = _backend.newId('tok');
    _backend.table('sessions')[token] = user.email;
    return Session(token: token, user: user);
  }

  User _userFor(String token) {
    final email = _backend.table('sessions')[token] as String?;
    final account = email == null ? null : _backend.table('accounts')[email] as Map?;
    if (account == null) {
      throw const ApiException('unauthorized', 'Your session has expired. Log in again.', status: 401);
    }
    return User.fromJson((account['user']! as Map).cast());
  }

  /// The user a session token belongs to. Throws `unauthorized` when unknown.
  User userFor(String token) => _userFor(token);
}
