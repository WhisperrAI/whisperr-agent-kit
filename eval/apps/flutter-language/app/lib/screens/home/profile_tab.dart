import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fake_backend.dart';
import '../../data/fixtures.dart';
import '../../data/models.dart';
import '../../state/auth_controller.dart';
import '../../state/subscription_controller.dart';
import '../../widgets/common.dart';
import '../billing/manage_subscription_screen.dart';
import '../billing/paywall_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  String _planLabel(Subscription? subscription) {
    final plan = plans.where((p) => p.id == subscription?.planId).firstOrNull;
    if (subscription == null || plan == null) return 'Free plan';
    if (subscription.status == SubscriptionStatus.canceled) {
      return 'Premium ${plan.title}: Canceled, active until ${formatDate(subscription.renewsAt)}';
    }
    return 'Premium ${plan.title}: renews ${formatDate(subscription.renewsAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user!;
    final subscription = context.watch<SubscriptionController>().subscription;
    final backend = context.read<FakeBackend>();
    return Scaffold(
      key: const Key('profile-screen'),
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
          Text(user.email),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Plan'),
            subtitle: Text(_planLabel(subscription), key: const Key('profile-plan')),
          ),
          if (subscription != null)
            SecondaryButton(
              key: const Key('profile-manage-subscription'),
              label: 'Manage subscription',
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => const ManageSubscriptionScreen())),
            )
          else
            SecondaryButton(
              key: const Key('profile-upgrade'),
              label: 'Go Premium',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const PaywallScreen(source: PaywallSource.profile),
              )),
            ),
          const Divider(height: 32),
          ValueListenableBuilder<bool>(
            valueListenable: backend.offline,
            builder: (context, offline, _) => SwitchListTile(
              key: const Key('dev-network-failure'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Simulate network failure'),
              subtitle: const Text('Developer setting'),
              value: offline,
              onChanged: (value) => backend.offline.value = value,
            ),
          ),
          const SizedBox(height: 16),
          SecondaryButton(key: const Key('profile-logout'), label: 'Log out', onPressed: auth.logOut),
        ],
      ),
    );
  }
}
