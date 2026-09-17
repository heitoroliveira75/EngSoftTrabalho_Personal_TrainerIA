import 'package:flutter/material.dart';

void main() {
  runApp(const MeuAppTreino());
}

class MeuAppTreino extends StatelessWidget {
  const MeuAppTreino({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'SEJA BEM-VINDO\nCAMPEÃO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              const Text(
                'PRONTO PARA TREINAR?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(28.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28.0),
                  onTap: () {
                    debugPrint('Botão pressionado!');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 24.0,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: Color(0xFF90CAF9),
                          size: 52,
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 60,
                          width: 1.2,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Começar o',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Treino',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}