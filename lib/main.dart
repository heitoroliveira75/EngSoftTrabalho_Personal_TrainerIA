import 'package:flutter/material.dart';

import 'screens/cadastro_screen.dart';
import 'screens/camera_treino_screen.dart';
import 'screens/change_name_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/criar_exercicio_screen.dart';
import 'screens/dificuldade_treino_screen.dart';
import 'screens/esqueceu_senha_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/opcao_treinos_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/redefinir_senha_screen.dart';
import 'screens/training_menu_screen.dart';
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
        '/redefinir-senha': (context) => const RedefinirSenhaScreen(),
        '/home': (context) => const HomeScreen(),
        '/treinos': (context) => const TreinosScreen(),
        '/treino-menu': (context) => const TrainingMenuScreen(),
        '/dificuldade': (context) => const DificuldadeScreen(),
        '/criar-treino': (context) => const CriarExercicioScreen(),
        '/criar': (context) => const CriarExercicioScreen(),
        '/opcao-treinos': (context) =>
            const OpcaoTreinosScreen(dificuldadeFlag: 'iniciante'),
        '/meus-treinos': (context) =>
            const OpcaoTreinosScreen(dificuldadeFlag: 'meus_treinos'),
        '/perfil': (context) => const ProfileScreen(),
        '/alterar-nome': (context) => const ChangeNameScreen(),
        '/alterar-senha': (context) => const ChangePasswordScreen(),
        '/camera-treino': (context) => const CameraTreinoScreen(),
      },
    );
  }
}
