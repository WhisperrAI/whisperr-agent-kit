import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fake_backend.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
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
      await context.read<AuthController>().logIn(_email.text, _password.text);
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
      key: const Key('login-screen'),
      appBar: AppBar(title: const Text('Welcome back')),
      body: PageBody(
        children: [
          ErrorBanner(key: const Key('login-error'), message: _error),
          TextField(
            key: const Key('login-email'),
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('login-password'),
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          PrimaryButton(key: const Key('login-submit'), label: 'Log in', busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
