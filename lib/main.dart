import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Import the generated firebase_options
import 'package:borkbook/providers/meal_provider.dart';
import 'package:borkbook/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => MealProvider()),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}
