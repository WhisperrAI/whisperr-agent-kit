import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'data/auth_repository.dart';
import 'data/billing_repository.dart';
import 'data/fake_backend.dart';
import 'data/lesson_repository.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'state/auth_controller.dart';
import 'state/progress_controller.dart';
import 'state/subscription_controller.dart';

class ParlaApp extends StatefulWidget {
  const ParlaApp({super.key, required this.backend});

  final FakeBackend backend;

  @override
  State<ParlaApp> createState() => _ParlaAppState();
}

class _ParlaAppState extends State<ParlaApp> {
  late final AuthController _auth;
  late final ProgressController _progress;
  late final SubscriptionController _subscription;

  @override
  void initState() {
    super.initState();
    final authRepository = AuthRepository(widget.backend);
    _auth = AuthController(authRepository);
    _progress = ProgressController(LessonRepository(widget.backend, authRepository), _auth);
    _subscription = SubscriptionController(BillingRepository(widget.backend, authRepository), _auth);
    _auth.restore();
    _progress.loadLessons();
  }

  @override
  void dispose() {
    _subscription.dispose();
    _progress.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.backend),
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _progress),
        ChangeNotifierProvider.value(value: _subscription),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE4572E)),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const _RootGate(),
      ),
    );
  }
}

/// Picks the flow for the auth state. Each flow has its own navigator, so
/// signing in or out drops the screens of the previous flow.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return switch (auth.status) {
      AuthStatus.restoring => const Scaffold(
          key: Key('splash-screen'),
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.signedOut => const _Flow(key: ValueKey('guest'), root: WelcomeScreen()),
      AuthStatus.signedIn when !auth.user!.onboarded =>
        const _Flow(key: ValueKey('onboarding'), root: OnboardingScreen()),
      AuthStatus.signedIn => const _Flow(key: ValueKey('member'), root: HomeShell()),
    };
  }
}

class _Flow extends StatefulWidget {
  const _Flow({super.key, required this.root});

  final Widget root;

  @override
  State<_Flow> createState() => _FlowState();
}

class _FlowState extends State<_Flow> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => widget.root),
      ),
    );
  }
}
