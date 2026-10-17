import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.status = 400});

  /// email_taken, invalid_credentials, card_declined, network_error,
  /// unauthorized, validation_error, not_found
  final String code;
  final String message;
  final int status;

  @override
  String toString() => 'ApiException($code, $message)';
}

/// A deterministic stand-in for Parla's API. Data lives in shared preferences
/// so it survives app restarts, every call takes [latency], and the network
/// can be switched off from the Profile screen.
class FakeBackend {
  FakeBackend._(this._prefs, this._db, this.latency);

  static const _storageKey = 'parla.fake_backend.v1';

  final SharedPreferences _prefs;
  final Map<String, Object?> _db;
  final Duration latency;
  final _random = Random();

  /// When true every request fails with `network_error`.
  final offline = ValueNotifier<bool>(false);

  static Future<FakeBackend> open({Duration latency = AppConfig.mockLatency}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    final db = raw == null ? <String, Object?>{} : (jsonDecode(raw) as Map).cast<String, Object?>();
    for (final table in ['accounts', 'sessions', 'results', 'subscriptions', 'feedback']) {
      db.putIfAbsent(table, () => table == 'feedback' ? <Object?>[] : <String, Object?>{});
    }
    return FakeBackend._(prefs, db, latency);
  }

  Map<String, Object?> table(String name) => (_db[name]! as Map).cast<String, Object?>();
  List<Object?> list(String name) => _db[name]! as List<Object?>;

  /// Runs [handler] like a network round trip: latency, then the offline check.
  Future<T> request<T>(T Function() handler) async {
    await Future<void>.delayed(latency);
    if (offline.value) {
      throw const ApiException('network_error', 'No connection. Check your network and try again.', status: 0);
    }
    final result = handler();
    await _prefs.setString(_storageKey, jsonEncode(_db));
    return result;
  }

  String newId(String prefix) => '${prefix}_${_random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0')}';

  /// Stable user id for an email, so the same account always gets the same id.
  static String userIdForEmail(String email) {
    final input = email.trim().toLowerCase();
    String fnv(int seed) {
      var hash = seed;
      for (final unit in input.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x01000193) & 0xffffffff;
      }
      return hash.toRadixString(16).padLeft(8, '0');
    }

    return 'usr_${fnv(0x811c9dc5)}${fnv(0x2f2f2f2f)}';
  }
}

String messageFor(Object error) =>
    error is ApiException ? error.message : 'Something went wrong. Please try again.';
