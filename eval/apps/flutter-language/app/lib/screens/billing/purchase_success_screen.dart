import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../widgets/common.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({super.key, required this.plan, required this.receipt});

  final Plan plan;
  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('purchase-success-screen'),
      body: PageBody(
        children: [
          const SizedBox(height: 48),
          Text("You're Premium!", style: text.displaySmall),
          const SizedBox(height: 12),
          Text(
            'We charged ${formatPrice(receipt.amountCents, receipt.currency)} for the ${plan.title.toLowerCase()} plan. '
            'It renews on ${formatDate(receipt.subscription.renewsAt)}.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            key: const Key('purchase-success-done'),
            label: 'Start learning',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
