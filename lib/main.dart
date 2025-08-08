// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart'; // Import the auth wrapper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DailyBuddyApp());
}

class DailyBuddyApp extends StatelessWidget {
  const DailyBuddyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyBuddy',
      theme: ThemeData(
        // ... Your theme data remains unchanged ...
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}