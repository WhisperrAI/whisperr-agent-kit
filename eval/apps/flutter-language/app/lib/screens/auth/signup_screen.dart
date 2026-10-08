import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fake_backend.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _marketingOptIn = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().signUp(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
            marketingOptIn: _marketingOptIn,
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
    return Scaffold(
      key: const Key('signup-screen'),
      appBar: AppBar(title: const Text('Create your account')),
      body: PageBody(
        children: [
          ErrorBanner(key: const Key('signup-error'), message: _error),
          TextField(
            key: const Key('signup-name'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('signup-email'),
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('signup-password'),
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password', helperText: 'At least 8 characters'),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('signup-marketing-consent'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Email me learning tips and offers'),
            subtitle: const Text('You can unsubscribe at any time.'),
            value: _marketingOptIn,
            onChanged: (value) => setState(() => _marketingOptIn = value),
          ),
          const SizedBox(height: 16),
          PrimaryButton(key: const Key('signup-submit'), label: 'Create account', busy: _busy, onPressed: _submit),
          SecondaryButton(
            key: const Key('signup-login-link'),
            label: 'I already have an account',
            onPressed: () => Navigator.of(context)
                .pushReplacement(MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
    );
  }
}
