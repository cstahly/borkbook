import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/meal_provider.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for local storage
import 'firebase_options.dart'; // Firebase initialization options
import 'package:firebase_core/firebase_core.dart'; // Firebase core
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
            seedColor: Colors.purple,
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

  // Request permissions for iOS
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Display a toast or snackbar
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(content: Text(message.notification?.body ?? 'New notification')),
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
