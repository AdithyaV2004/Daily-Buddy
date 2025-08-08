
import 'package:dddd_buddy/screens/auth/login_screen.dart' show LoginPage;
import 'package:dddd_buddy/screens/home/home_screen.dart' show HomePage;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:flutter/material.dart' show StatelessWidget, BuildContext, Key, Widget, Scaffold, ConnectionState, CircularProgressIndicator, Center, StreamBuilder;

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return HomePage(userId: snapshot.data!.uid);
        }
        return const LoginPage();
      },
    );
  }
}