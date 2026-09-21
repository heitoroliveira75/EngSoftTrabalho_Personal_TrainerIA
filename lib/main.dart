import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

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
                builder: (context) => const SecondRoute(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Tela de exemplo de destino
class SecondRoute extends StatelessWidget {
  const SecondRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Treino Iniciado'),
        backgroundColor: const Color(0xFF2B2B2B),
      ),
      body: const Center(
        child: Text(
          'Bons treinos!',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}