import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Optional: set Auth language to avoid the null-locale warnings
  // import 'package:firebase_auth/firebase_auth.dart';
  // FirebaseAuth.instance.setLanguageCode('en');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      textTheme: Typography.blackMountainView,
    );

    return MaterialApp(
      title: 'Firebase Lab',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
