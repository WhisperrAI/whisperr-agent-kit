import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/billing_repository.dart';
import '../../data/fake_backend.dart';
import '../../data/models.dart';
import '../../state/auth_controller.dart';
import '../../state/subscription_controller.dart';
import '../../widgets/common.dart';
import 'paywall_screen.dart';
import 'purchase_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.plan, required this.source});

  final Plan plan;
  final PaywallSource source;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _card = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  late final TextEditingController _address;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final email = context.read<AuthController>().user?.email ?? '';
    _address = TextEditingController(text: context.read<SubscriptionController>().billingAddressFor(email));
  }

  @override
  void dispose() {
    _card.dispose();
    _expiry.dispose();
    _cvc.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await context.read<SubscriptionController>().purchase(PurchaseRequest(
            planId: widget.plan.id,
            cardNumber: _card.text,
            expiry: _expiry.text,
            cvc: _cvc.text,
            billingAddress: _address.text,
          ));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => PurchaseSuccessScreen(plan: widget.plan, receipt: receipt)),
        (route) => route.isFirst,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = messageFor(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Scaffold(
      key: const Key('checkout-screen'),
      appBar: AppBar(title: const Text('Checkout')),
      body: PageBody(
        children: [
          Text('Parla Premium · ${plan.title}', style: Theme.of(context).textTheme.titleLarge),
          Text('${formatPrice(plan.priceCents, plan.currency)} per ${plan.period.name}'),
          const SizedBox(height: 24),
          ErrorBanner(key: const Key('checkout-error'), message: _error),
          TextField(
            key: const Key('checkout-card-number'),
            controller: _card,
            decoration: const InputDecoration(labelText: 'Card number'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('checkout-expiry'),
                  controller: _expiry,
                  decoration: const InputDecoration(labelText: 'MM/YY'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('checkout-cvc'),
                  controller: _cvc,
                  decoration: const InputDecoration(labelText: 'CVC'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('checkout-billing-address'),
            controller: _address,
            decoration: const InputDecoration(labelText: 'Billing address'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            key: const Key('checkout-submit'),
            label: 'Pay ${formatPrice(plan.priceCents, plan.currency)}',
            busy: _busy,
            onPressed: _pay,
          ),
        ],
      ),
    );
  }
}
