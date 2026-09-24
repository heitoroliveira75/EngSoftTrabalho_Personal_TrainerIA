import 'package:flutter/material.dart';
import 'screens/cadastro_screen.dart';
import 'screens/esqueceu_senha_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/treinos_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeuAppTreino());
}

class MeuAppTreino extends StatelessWidget {
  const MeuAppTreino({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Trainer IA',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFFE91E63),
          surface: Color(0xFF1E232A),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/esqueceu-senha': (context) => const EsqueceuSenhaScreen(),
        '/home': (context) => const HomeScreen(),
        '/treinos': (context) => const TreinosScreen(),
      },
    );
  }
}