import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import 'cadastro_screen.dart';
import 'esqueceu_senha_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _executarLogin({bool forcarLogin = false}) async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o e-mail e a senha.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    final resposta = await ApiService().fazerLogin(
      email: email,
      senha: senha,
      forcarLogin: forcarLogin,
    );

    if (!mounted) return;

    setState(() {
      _carregando = false;
    });

    if (resposta['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Login realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Redireciona para a tela Home limpando a pilha de telas
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else if (resposta['ja_conectado'] == true) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E232A),
          title: const Row(
            children: [
              Icon(Icons.devices_other, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Conta já conectada',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            resposta['mensagem'] != null
                ? '${resposta['mensagem']}\n\nDeseja desconectar o outro aparelho e entrar neste dispositivo?'
                : 'Este usuário já está conectado em outro dispositivo.\n\nDeseja desconectar o outro aparelho e entrar neste dispositivo?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Desconectar outro e entrar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirmar == true && mounted) {
        await _executarLogin(forcarLogin: true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Falha ao realizar login.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_carregando) _executarLogin();
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (!_carregando) _executarLogin();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF0D1117), // Fundo escuro
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título LOGIN
                    const Text(
                      'LOGIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Campo E-mail / Usuário
                    _buildInputField(
                      controller: _emailController,
                      hintText: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        if (!_carregando) _executarLogin();
                      },
                    ),

                    const SizedBox(height: 16),

                    // Campo Senha
                    _buildInputField(
                      controller: _senhaController,
                      hintText: 'Senha',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_carregando) _executarLogin();
                      },
                    ),

                    const SizedBox(height: 16),

                    // Botão Continuar / Login
                    ElevatedButton(
                      onPressed: _carregando ? null : () => _executarLogin(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: const Color(0xFF0D1117),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: _carregando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0D1117),
                              ),
                            )
                          : const Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // Link "Esqueceu a senha?"
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EsqueceuSenhaScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Rodapé "Não possui uma conta? Crie uma conta"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CadastroScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Crie uma conta',
                              style: TextStyle(
                                color: Color(0xFF00E676), // Rosa vibrante
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para os campos de texto em cinza carbono
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1E232A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
      ),
    );
  }
}
