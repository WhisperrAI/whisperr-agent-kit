import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fake_backend.dart';
import '../../data/models.dart';
import '../../state/subscription_controller.dart';
import '../../widgets/common.dart';

class CancelSubscriptionScreen extends StatefulWidget {
  const CancelSubscriptionScreen({super.key});

  @override
  State<CancelSubscriptionScreen> createState() => _CancelSubscriptionScreenState();
}

class _CancelSubscriptionScreenState extends State<CancelSubscriptionScreen> {
  final _feedback = TextEditingController();
  CancelReason? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<SubscriptionController>().cancel(reason, _feedback.text.trim());
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('cancel-subscription-screen'),
      appBar: AppBar(title: const Text('Cancel Premium')),
      body: PageBody(
        children: [
          Text("We're sorry to see you go. Why are you canceling?", style: text.titleMedium),
          const SizedBox(height: 16),
          ErrorBanner(message: _error),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in CancelReason.values)
                ChoiceChip(
                  key: Key('cancel-reason-${reason.id}'),
                  label: Text(reason.label),
                  selected: _reason == reason,
                  onSelected: (_) => setState(() => _reason = reason),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('cancel-feedback'),
            controller: _feedback,
            decoration: const InputDecoration(labelText: 'Anything else we should know? (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            key: const Key('cancel-confirm'),
            label: 'Cancel subscription',
            busy: _busy,
            onPressed: _reason == null ? null : _confirm,
          ),
          SecondaryButton(
            key: const Key('cancel-keep'),
            label: 'Keep Premium',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
