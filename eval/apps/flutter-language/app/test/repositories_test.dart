import 'package:flutter_test/flutter_test.dart';
import 'package:parla/data/auth_repository.dart';
import 'package:parla/data/billing_repository.dart';
import 'package:parla/data/fake_backend.dart';
import 'package:parla/data/lesson_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeBackend backend;
  late AuthRepository auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = await FakeBackend.open(latency: Duration.zero);
    auth = AuthRepository(backend);
  });

  Future<String> signUp(String email) async => (await auth.signUp(
        fullName: 'Test Learner',
        email: email,
        password: 'long-enough-1',
        marketingOptIn: false,
      ))
          .token;

  test('user ids are stable per email', () {
    expect(FakeBackend.userIdForEmail('Learner@Example.com'), FakeBackend.userIdForEmail('learner@example.com'));
    expect(FakeBackend.userIdForEmail('learner@example.com'), matches(RegExp(r'^usr_[0-9a-f]{16}$')));
  });

  test('signing up with a taken email fails', () {
    expect(signUp('taken@example.com'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'email_taken')));
  });

  test('the decline card is declined', () async {
    final token = await signUp('learner@example.com');
    final billing = BillingRepository(backend, auth);
    final request = PurchaseRequest(
      planId: 'premium_monthly',
      cardNumber: '4000 0000 0000 0002',
      expiry: '12/30',
      cvc: '123',
      billingAddress: '',
    );
    expect(billing.purchase(token, request),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'card_declined')));
  });

  test('lessons are graded', () async {
    final token = await signUp('learner@example.com');
    final result = await LessonRepository(backend, auth).completeLesson(token, 'les_greetings', [0, 1, 2]);
    expect(result.correct, 2);
    expect(result.scorePercent, 67);
  });

  test('requests fail while offline', () async {
    backend.offline.value = true;
    expect(signUp('learner@example.com'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'network_error')));
  });
}
