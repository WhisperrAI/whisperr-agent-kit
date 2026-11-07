import 'package:flutter/material.dart';

import 'app.dart';
import 'data/fake_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backend = await FakeBackend.open();
  runApp(ParlaApp(backend: backend));
}
