import 'auth_repository.dart';
import 'fake_backend.dart';
import 'fixtures.dart';
import 'models.dart';

class PurchaseRequest {
  const PurchaseRequest({
    required this.planId,
    required this.cardNumber,
    required this.expiry,
    required this.cvc,
    required this.billingAddress,
  });

  final String planId;
  final String cardNumber;
  final String expiry;
  final String cvc;
  final String billingAddress;
}

class BillingRepository {
  BillingRepository(this._backend, this._auth);

  final FakeBackend _backend;
  final AuthRepository _auth;

  Future<List<Plan>> listPlans() => _backend.request(() => plans);

  Future<Subscription?> getSubscription(String token) {
    return _backend.request(() {
      final stored = _backend.table('subscriptions')[_auth.userFor(token).id] as Map?;
      return stored == null ? null : Subscription.fromJson(stored.cast());
    });
  }

  /// The billing address on file for an account, used to prefill checkout.
  String billingAddressFor(String email) => demoProfiles[email.trim().toLowerCase()]?.billingAddress ?? '';

  Future<Receipt> purchase(String token, PurchaseRequest request) {
    return _backend.request(() {
      final user = _auth.userFor(token);
      final plan = plans.where((p) => p.id == request.planId).firstOrNull;
      if (plan == null) throw const ApiException('not_found', 'That plan is not available.', status: 404);
      final card = request.cardNumber.replaceAll(RegExp(r'\s'), '');
      if (!RegExp(r'^\d{16}$').hasMatch(card)) {
        throw const ApiException('validation_error', 'Enter the 16-digit card number.');
      }
      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(request.expiry.trim()) ||
          !RegExp(r'^\d{3,4}$').hasMatch(request.cvc.trim())) {
        throw const ApiException('validation_error', 'Check the expiry date and security code.');
      }
      if (declinedCards.contains(card)) {
        throw const ApiException('card_declined', 'Your card was declined. Try another card.', status: 402);
      }
      final now = DateTime.now().toUtc();
      final subscription = Subscription(
        planId: plan.id,
        status: SubscriptionStatus.active,
        renewsAt: plan.period == BillingPeriod.year
            ? DateTime.utc(now.year + 1, now.month, now.day)
            : DateTime.utc(now.year, now.month + 1, now.day),
      );
      _backend.table('subscriptions')[user.id] = subscription.toJson();
      return Receipt(subscription: subscription, amountCents: plan.priceCents, currency: plan.currency);
    });
  }

  Future<Subscription> cancel(String token, CancelReason reason, String feedback) {
    return _backend.request(() {
      final user = _auth.userFor(token);
      final stored = _backend.table('subscriptions')[user.id] as Map?;
      if (stored == null) throw const ApiException('not_found', 'You have no active subscription.', status: 404);
      final current = Subscription.fromJson(stored.cast());
      final canceled = Subscription(
        planId: current.planId,
        status: SubscriptionStatus.canceled,
        renewsAt: current.renewsAt,
        canceledAt: DateTime.now().toUtc(),
      );
      _backend.table('subscriptions')[user.id] = canceled.toJson();
      _backend.list('feedback').add({'userId': user.id, 'reason': reason.id, 'feedback': feedback});
      return canceled;
    });
  }
}
