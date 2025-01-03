import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/meal_provider.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import the appropriate service worker helper based on the platform
import 'service_worker_helper.dart'
    if (dart.library.html) 'service_worker_helper_web.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the service worker (only on web)
  await registerServiceWorker();

  await setupFCM();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => MealProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData(
          useMaterial3: true,

          // Define the default brightness and colors.
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.brown,
            // TRY THIS: Change to "Brightness.light"
            //           and see that all colors change
            //           to better contrast a light background.
            brightness: Brightness.dark,
          ),

          // Define the default `TextTheme`. Use this to specify the default
          // text styling for headlines, titles, bodies of text, and more.
          textTheme: TextTheme(
            displayLarge: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: HomeScreen(),
      ),
    );
  }
}

Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    // Request permissions for iOS only (skip for web where permissions might be blocked)
    //if (!kIsWeb) {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('FCM permission settings: ${settings.authorizationStatus}');
    //}

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Display a toast or snackbar
      ScaffoldMessenger.of(navigatorKey.currentContext!)?.showSnackBar(
        SnackBar(
            content: Text(message.notification?.body ?? 'New notification')),
      );
    });

    // Get the device token and send it to the server
    String? token = await messaging.getToken();
    if (token != null) {
      // Send the token to your server
      await sendTokenToServer(token);
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // Send the new token to your server
      sendTokenToServer(newToken);
    });
  } catch (e) {
    // Log a warning if FCM setup fails
    print('FCM setup failed: $e');
  }
}

Future<void> sendTokenToServer(String token) async {
  // Implement the API call to send the token to your server
  final response = await http.post(
    Uri.parse('https://freepuppyservices.com:4444/register-token'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': token}),
  );
  if (response.statusCode == 200) {
    print('Token registered successfully');
  } else {
    print('Failed to register token');
  }
}
