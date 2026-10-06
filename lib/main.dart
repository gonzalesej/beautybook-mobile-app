// ─────────────────────────────────────────────────────────
// Project structure follows an MVC-style separation:
// - Model:      lib/models/       (data classes: Appointment, ServiceItem, EmployeeProfile)
// - View:       lib/screens/, lib/widgets/   (UI screens and reusable widgets)
// - Controller: lib/services/     (Firebase/Firestore logic: repositories that
//                                   fetch, watch, and update data for the Views)
// ─────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/auth/authenticator.dart';
import 'package:flutter_firebase/firebase_options.dart';
import 'package:flutter_firebase/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeautyBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Authenticator(),
    );
  }
}