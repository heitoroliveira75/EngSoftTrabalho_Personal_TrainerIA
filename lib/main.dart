import 'package:flutter/material.dart';

void main() {
  runApp(const MeuAplicativo());
}

class MeuAplicativo extends StatelessWidget {
  const MeuAplicativo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove a faixa de debug no canto
      title: 'App de Login',
      home: const LoginPage(), 
    );
  }
}



class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A cor extraída do bloco HTML principal
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Realize Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // Campo Usuário
              TextField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white, // Fundo branco extraído do HTML
                  hintText: 'Usuário',
                  hintStyle: const TextStyle(color: Color(0xFF828282)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Senha
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Senha',
                  hintStyle: const TextStyle(color: Color(0xFF828282)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão Continuar
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                child: const Text('Continuar', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 24),

              // Linha divisória "ou"
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFE6E6E6))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ou', style: TextStyle(color: Color(0xFF828282))),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE6E6E6))),
                ],
              ),
              const SizedBox(height: 24),

              // Botão Google
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.g_mobiledata, color: Colors.black, size: 28),
                label: const Text('Continuar com o Google', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botão Apple
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.apple, color: Colors.black, size: 28),
                label: const Text('Continuar com a Apple', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}