import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'treinos_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onSecondRoute;

  const HomeScreen({super.key, this.onSecondRoute});

  @override
  Widget build(BuildContext context) {
    final usuario = ApiService().usuarioLogado;
    final nomeUsuario = usuario != null && usuario['nome'] != null
        ? usuario['nome']
        : (usuario != null && usuario['user_metadata'] != null && usuario['user_metadata']['nome'] != null)
            ? usuario['user_metadata']['nome']
            : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (usuario != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              tooltip: 'Sair da conta',
              onPressed: () async {
                await ApiService().deslogar();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                nomeUsuario != null
                    ? 'SEJA BEM-VINDO,\n${nomeUsuario.toString().toUpperCase()}'
                    : 'SEJA BEM-VINDO\nCAMPEÃO',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
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
                    if (onSecondRoute != null) {
                      onSecondRoute!();
                    } else {
                      // Abre a tela de treinos
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TreinosScreen(),
                        ),
                      );
                    }
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
