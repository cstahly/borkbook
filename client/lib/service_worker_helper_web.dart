// service_worker_helper_web.dart

import 'dart:html' as html;

Future<void> registerServiceWorker() async {
  try {
    await html.window.navigator.serviceWorker
        ?.register('/firebase-messaging-sw.js');
    print('Service Worker registered successfully');
  } catch (e) {
    print('Service Worker registration failed: $e');
  }
}
