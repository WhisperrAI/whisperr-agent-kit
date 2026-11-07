import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fixtures.dart';
import '../../data/models.dart';
import '../../state/subscription_controller.dart';
import '../../widgets/common.dart';
import 'cancel_subscription_screen.dart';

class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionController>().subscription;
    final plan = plans.where((p) => p.id == subscription?.planId).firstOrNull;
    return Scaffold(
      key: const Key('manage-subscription-screen'),
      appBar: AppBar(title: const Text('Subscription')),
      body: PageBody(
        children: [
          if (subscription == null || plan == null)
            const Text('You are on the free plan.', key: Key('subscription-status'))
          else ...[
            Text('Parla Premium · ${plan.title}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subscription.status == SubscriptionStatus.active
                  ? 'Renews on ${formatDate(subscription.renewsAt)} for ${formatPrice(plan.priceCents, plan.currency)}.'
                  : 'Canceled. Premium stays on until ${formatDate(subscription.renewsAt)}.',
              key: const Key('subscription-status'),
            ),
            const SizedBox(height: 32),
            if (subscription.status == SubscriptionStatus.active)
              SecondaryButton(
                key: const Key('subscription-cancel'),
                label: 'Cancel subscription',
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const CancelSubscriptionScreen())),
              ),
          ],
        ],
      ),
    );
  }
}
