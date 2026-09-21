import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MeuAppTreino());
}

class MeuAppTreino extends StatelessWidget {
  const MeuAppTreino({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => HomeScreen(
          onSecondRoute: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}