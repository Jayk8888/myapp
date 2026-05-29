import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'src/web_engine_guard_stub.dart'
    if (dart.library.html) 'src/web_engine_guard_web.dart';

Future<void> main() async {
  installWebEngineGuard();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
