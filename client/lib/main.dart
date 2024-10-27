import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/meal_provider.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for local storage
import 'firebase_options.dart'; // Firebase initialization options
import 'package:firebase_core/firebase_core.dart'; // Firebase core

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
