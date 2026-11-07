// Drives the Parla UI through the eval flows and writes one JSON line per step
// to EVAL_OUT. It only touches the UI (Keys), the simulated OS lifecycle and
// storage; it never imports the app's analytics code.
//
// driver/run copies this file into the app under eval_driver_test/ and
// replaces __APP_PACKAGE__ with the package name from pubspec.yaml.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:__APP_PACKAGE__/main.dart' as app;

final _env = Platform.environment;
final _out = _env['EVAL_OUT'] ?? '';
final _apiBase = Uri.parse(_env['EVAL_API_BASE'] ?? 'http://localhost:8080');
final _flushWait = Duration(milliseconds: int.parse(_env['EVAL_FLUSH_WAIT_MS'] ?? '12000'));
final _findTimeout = Duration(milliseconds: int.parse(_env['EVAL_FIND_TIMEOUT_MS'] ?? '10000'));
const _stepSettle = Duration(milliseconds: 600);

const _jane = (name: 'Jane Evalson', email: 'jane.eval@example.com', password: 'correct-horse-9');
const _sam = (name: 'Sam Optout', email: 'sam.noconsent@example.com', password: 'battery-staple-7');
const _goodCard = '4242424242424242';
const _declinedCard = '4000000000000002';

/// Real network for the SDK (flutter_test fakes HttpClient by default), and a
/// count of the requests that went to the Whisperr API.
class _ObservedHttp extends HttpOverrides {
  final byPath = <String, int>{};

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    if (url.host == _apiBase.host && url.port == _apiBase.port) {
      byPath.update(url.path, (n) => n + 1, ifAbsent: () => 1);
    }
    return 'DIRECT';
  }
}

void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final http = _ObservedHttp();

  testWidgets('eval flows', (tester) async {
    if (_out.isEmpty) fail('EVAL_OUT is required');
    HttpOverrides.global = http;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async => {
        'appName': 'Parla',
        'packageName': 'example.parla.parla',
        'version': '1.0.0',
        'buildNumber': '1',
        'buildSignature': '',
        'installerStore': null,
      },
    );
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;

    Future<void> sleep(Duration d) => Future<void>.delayed(d);

    // The OS walks through the intermediate states; AppLifecycleListener asserts that.
    Future<void> background() async {
      for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
        binding.handleAppLifecycleStateChanged(state);
      }
      await sleep(const Duration(milliseconds: 50));
    }

    Future<void> foreground() async {
      for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        binding.handleAppLifecycleStateChanged(state);
      }
      await sleep(const Duration(milliseconds: 50));
    }

    Future<void> waitFor(Finder finder, {String? what}) async {
      final deadline = DateTime.now().add(_findTimeout);
      while (finder.evaluate().isEmpty) {
        if (DateTime.now().isAfter(deadline)) throw StateError('timed out waiting for ${what ?? finder}');
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Finder byKey(String key) => find.byKey(Key(key));
    Future<void> shows(String key) => waitFor(byKey(key).hitTestable(), what: key);
    Future<void> gone(String key) async {
      final deadline = DateTime.now().add(_findTimeout);
      while (byKey(key).hitTestable().evaluate().isNotEmpty) {
        if (DateTime.now().isAfter(deadline)) throw StateError('$key still visible');
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Scrolls [key] into view; lazy lists keep built rows outside the viewport offstage.
    Future<void> reveal(String key) async {
      final built = find.byKey(Key(key), skipOffstage: false);
      await waitFor(built, what: key);
      await tester.ensureVisible(built.last);
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> tap(String key) async {
      await reveal(key);
      await shows(key);
      await tester.tap(byKey(key).hitTestable().first);
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> enter(String key, String text) async {
      await reveal(key);
      await tester.enterText(byKey(key).first, text);
      await tester.pump(const Duration(milliseconds: 50));
    }

    Future<void> expectText(String key, RegExp pattern) async {
      await reveal(key);
      final deadline = DateTime.now().add(_findTimeout);
      while (true) {
        final texts = byKey(key).evaluate().map((e) => e.widget).whereType<Text>().map((t) => t.data ?? '');
        final banner = find.descendant(of: byKey(key), matching: find.byType(Text));
        final all = [...texts, ...banner.evaluate().map((e) => (e.widget as Text).data ?? '')];
        if (all.any(pattern.hasMatch)) return;
        if (DateTime.now().isAfter(deadline)) throw StateError('$key text $all does not match $pattern');
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> launchApp() async {
      final result = Function.apply(app.main, const []);
      if (result is Future) await result;
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// The user leaves the app and the OS kills it.
    Future<void> killApp() async {
      await background();
      await sleep(const Duration(milliseconds: 1500));
      await foreground();
      await tester.pumpWidget(const SizedBox.shrink());
    }

    Future<void> step(String id, Future<void> Function(void Function(String) mark) body) async {
      final startedAt = DateTime.now().toUtc();
      final marks = <String, String>{};
      var ok = true;
      String? error;
      try {
        await body((name) => marks[name] = DateTime.now().toUtc().toIso8601String());
      } catch (e) {
        ok = false;
        error = e.toString().split('\n').first;
        if (error.length > 300) error = error.substring(0, 300);
        if (_env['EVAL_DEBUG'] != null) {
          final keys = find
              .byWidgetPredicate((w) => w.key is ValueKey<String>)
              .hitTestable()
              .evaluate()
              .map((e) => '${(e.widget.key! as ValueKey<String>).value}:${e.widget.runtimeType}');
          // ignore: avoid_print
          print('visible keys: ${keys.join(', ')}');
          final all = find
              .byWidgetPredicate((w) => w.key is ValueKey<String>, skipOffstage: false)
              .evaluate()
              .map((e) => (e.widget.key! as ValueKey<String>).value);
          // ignore: avoid_print
          print('all keys: ${all.join(', ')}');
        }
      }
      // Let work that follows the visible result (awaits after navigation) land inside the step.
      await tester.pump(_stepSettle);
      final line = <String, Object?>{
        'step': id,
        'started_at': startedAt.toIso8601String(),
        'ended_at': DateTime.now().toUtc().toIso8601String(),
        'ok': ok,
        if (marks.isNotEmpty) 'marks': marks,
        if (!ok) 'error': error,
      };
      File(_out).writeAsStringSync('${jsonEncode(line)}\n', mode: FileMode.append, flush: true);
      // ignore: avoid_print
      print('${ok ? 'ok  ' : 'FAIL'} $id${ok ? '' : ' ($error)'}');
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> signUp(({String name, String email, String password}) user, {required bool consent}) async {
      await enter('signup-name', user.name);
      await enter('signup-email', user.email);
      await enter('signup-password', user.password);
      if (consent) await tap('signup-marketing-consent');
      await tap('signup-submit');
    }

    Future<void> completeLesson(String lessonId) async {
      await tap('tab-learn');
      await tap('lesson-tile-$lessonId');
      for (var i = 0; i < 3; i++) {
        await tap('answer-option-${i % 2}');
        await tap('lesson-next');
      }
      await shows('lesson-result-screen');
      await tap('lesson-result-done');
      await shows('home-screen');
    }

    await step('anon_browse', (_) async {
      await launchApp();
      await shows('welcome-screen');
      await tap('lesson-card-les_greetings');
      await shows('lesson-preview-screen');
      await tap('lesson-start');
      await shows('signup-screen');
    });

    await step('signup_taken', (_) async {
      await signUp((name: _jane.name, email: 'taken@example.com', password: _jane.password), consent: true);
      await expectText('signup-error', RegExp('already exists'));
    });

    await step('signup_ok', (_) async {
      await enter('signup-email', _jane.email);
      await tap('signup-submit');
      await shows('onboarding-step-reason');
    });

    await step('onboarding_done', (_) async {
      await tap('reason-option-travel');
      await tap('onboarding-next');
      await tap('level-option-elementary');
      await tap('onboarding-next');
      await tap('daily-goal-option-15');
      await tap('onboarding-finish');
      await shows('home-screen');
    });

    await step('core_action_x3', (_) async {
      await completeLesson('les_greetings');
      await completeLesson('les_cafe');
      await completeLesson('les_directions');
      await expectText('home-daily-progress', RegExp(r'^15 of 15 minutes'));
    });

    await step('paywall_view', (_) async {
      await tap('home-upgrade');
      await shows('paywall-screen');
      await waitFor(byKey('plan-option-premium_annual'));
    });

    await step('purchase_declined', (_) async {
      await tap('plan-option-premium_annual');
      await tap('paywall-continue');
      await enter('checkout-card-number', _declinedCard);
      await enter('checkout-expiry', '12/30');
      await enter('checkout-cvc', '123');
      await tap('checkout-submit');
      await expectText('checkout-error', RegExp('declined'));
    });

    await step('purchase_ok', (_) async {
      await enter('checkout-card-number', _goodCard);
      await tap('checkout-submit');
      await shows('purchase-success-screen');
      await tap('purchase-success-done');
      await shows('home-screen');
    });

    await step('cancel_with_reason', (_) async {
      await tap('tab-profile');
      await tap('profile-manage-subscription');
      await tap('subscription-cancel');
      await tap('cancel-reason-too_expensive');
      await enter('cancel-feedback', 'Money is tight this month');
      await tap('cancel-confirm');
      await shows('profile-screen');
      await expectText('profile-plan', RegExp('Canceled'));
    });

    await step('logout', (_) async {
      await tap('profile-logout');
      await shows('welcome-screen');
      // Jane logs back in next, so stitching moves this anonymous browse onto her
      // whether or not the SDK was reset; signup_ok_noconsent checks the reset.
      await tap('lesson-card-les_cafe');
      await shows('lesson-preview-screen');
    });

    await step('login_ok', (_) async {
      await tap('lesson-start');
      await tap('signup-login-link');
      await enter('login-email', _jane.email);
      await enter('login-password', _jane.password);
      await tap('login-submit');
      await shows('home-screen');
    });

    await step('restore', (_) async {
      await killApp();
      await launchApp();
      await shows('home-screen');
    });

    await step('signup_ok_noconsent', (mark) async {
      await tap('tab-profile');
      await tap('profile-logout');
      await shows('welcome-screen');
      // From here until Sam signs up the device is anonymous: the lifecycle
      // events of this background/foreground cycle must not carry Jane's id.
      mark('logout_at');
      await sleep(const Duration(milliseconds: 50)); // events are stored with millisecond precision
      await background();
      await sleep(const Duration(milliseconds: 1500));
      await foreground();
      await tap('lesson-card-les_hotel');
      await shows('lesson-preview-screen');
      await tap('lesson-start');
      await shows('signup-screen');
      mark('signup_at');
      await signUp(_sam, consent: false);
      await shows('onboarding-step-reason');
    });

    // Leave the app so the SDK flushes, then give delivery time to finish.
    await background();
    await sleep(_flushWait);
    // ignore: avoid_print
    print('whisperr api requests: ${jsonEncode(http.byPath)}');
    await foreground();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
