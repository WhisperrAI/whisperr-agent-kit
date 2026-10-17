import 'package:flutter/foundation.dart';

import '../data/billing_repository.dart';
import '../data/models.dart';
import 'auth_controller.dart';

class SubscriptionController extends ChangeNotifier {
  SubscriptionController(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final BillingRepository _repository;
  final AuthController _auth;
  String? _token;
  Subscription? _subscription;

  Subscription? get subscription => _subscription;
  bool get isPremium => _subscription?.grantsPremium ?? false;

  Future<List<Plan>> listPlans() => _repository.listPlans();

  String billingAddressFor(String email) => _repository.billingAddressFor(email);

  Future<Receipt> purchase(PurchaseRequest request) async {
    final token = _token;
    if (token == null) throw StateError('Not signed in');
    final receipt = await _repository.purchase(token, request);
    _subscription = receipt.subscription;
    notifyListeners();
    return receipt;
  }

  Future<Subscription> cancel(CancelReason reason, String feedback) async {
    final token = _token;
    if (token == null) throw StateError('Not signed in');
    final next = await _repository.cancel(token, reason, feedback);
    _subscription = next;
    notifyListeners();
    return next;
  }

  void _onAuthChanged() {
    final token = _auth.token;
    if (token == _token) return;
    _token = token;
    _subscription = null;
    notifyListeners();
    if (token != null) {
      _repository.getSubscription(token).then((loaded) {
        if (_token != token) return;
        _subscription = loaded;
        notifyListeners();
      }, onError: (Object _) {});
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
