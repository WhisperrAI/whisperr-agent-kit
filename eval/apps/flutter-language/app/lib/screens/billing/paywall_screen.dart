import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fake_backend.dart';
import '../../data/models.dart';
import '../../state/subscription_controller.dart';
import '../../widgets/common.dart';
import 'checkout_screen.dart';

/// Where the learner opened the paywall from.
enum PaywallSource {
  homeBanner('home_banner'),
  lockedLesson('locked_lesson'),
  profile('profile');

  const PaywallSource(this.id);
  final String id;
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, required this.source});

  final PaywallSource source;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  static const _perks = ['Every unit, including Travel', 'Unlimited lesson replays', 'Offline audio'];

  List<Plan> _plans = const [];
  String _selected = 'premium_annual';
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionController>().listPlans().then(
      (plans) {
        if (mounted) setState(() => _plans = plans);
      },
      onError: (Object error) {
        if (mounted) setState(() => _error = messageFor(error));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('paywall-screen'),
      appBar: AppBar(),
      body: PageBody(
        children: [
          Text('Parla Premium', style: text.headlineMedium),
          const SizedBox(height: 12),
          for (final perk in _perks) ListTile(leading: const Icon(Icons.check), title: Text(perk), dense: true),
          const SizedBox(height: 12),
          ErrorBanner(message: _error),
          for (final plan in _plans)
            Card(
              child: ListTile(
                key: Key('plan-option-${plan.id}'),
                title: Text(plan.title),
                subtitle: Text('${formatPrice(plan.priceCents, plan.currency)} per ${plan.period.name}'),
                trailing: Icon(plan.id == _selected ? Icons.radio_button_checked : Icons.radio_button_off),
                selected: plan.id == _selected,
                onTap: () => setState(() => _selected = plan.id),
              ),
            ),
          const SizedBox(height: 24),
          PrimaryButton(
            key: const Key('paywall-continue'),
            label: 'Continue',
            onPressed: _plans.isEmpty
                ? null
                : () {
                    final plan = _plans.firstWhere((p) => p.id == _selected);
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => CheckoutScreen(plan: plan, source: widget.source),
                    ));
                  },
          ),
          SecondaryButton(
            key: const Key('paywall-dismiss'),
            label: 'Not now',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
