import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('window.location')
external _Location get _location;

extension type _Location._(JSObject _) {
  external void reload();
}

/// Recovers from Flutter web CanvasKit hot-restart engine bugs by reloading.
void installWebEngineGuard() {
  if (!kDebugMode) return;

  final prior = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    final details = '$error\n$stack';
    final isCanvasKitSurfaceBug = details.contains('LateInitializationError') &&
        details.contains('_handledContextLostEvent');

    if (isCanvasKitSurfaceBug) {
      _location.reload();
      return true;
    }

    return prior?.call(error, stack) ?? false;
  };
}
