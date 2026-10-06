import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import 'role_gate.dart';

class Authenticator extends StatefulWidget {
  const Authenticator({super.key});

  @override
  State<Authenticator> createState() => _AuthenticatorState();
}

class _AuthenticatorState extends State<Authenticator> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          } else if (snapshot.hasData) {
            // signed in -> customer, staff or manager app
            return RoleGate(user: snapshot.data!);
          } else {
            return const SplashScreen(); // signed out -> welcome screen
          }
        },
      ),
    );
  }
}