import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const IezDemoApp());
}

class IezDemoApp extends StatelessWidget {
  const IezDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iez Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
