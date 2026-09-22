import 'package:flutter/material.dart';

void main() {
  runApp(const MeuAppRedefinirSenha());
}

class MeuAppRedefinirSenha extends StatelessWidget {
  const MeuAppRedefinirSenha({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RedefinirSenhaScreen(),
    );
  }
}

class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmeSenhaController = TextEditingController();

  @override
  void dispose() {
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmeSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Fundo escuro padrão
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título: Esqueceu sua senha?
                const Text(
                  'Esqueceu sua senha?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 36),

                // Texto explicativo central
                const Text(
                  'Informe o codigo de segurança\n'
                  'enviado ao seu email e digite qual\n'
                  'sera sua nova senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.45,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 80),

                // Campo Código
                _buildInputField(
                  controller: _codigoController,
                  hintText: 'Codigo',
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Campo Nova senha
                _buildInputField(
                  controller: _novaSenhaController,
                  hintText: 'Nova senha',
                  obscureText: true,
                ),

                const SizedBox(height: 16),

                // Campo Confirme a senha
                _buildInputField(
                  controller: _confirmeSenhaController,
                  hintText: 'Confirme a senha',
                  obscureText: true,
                ),

                const SizedBox(height: 18),

                // Botão Continuar
                ElevatedButton(
                  onPressed: () {
                    debugPrint('Redefinir senha enviado');
                    Navigator.popUntil(context, ModalRoute.withName('/login'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF030712), // Preto / quase preto
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para os campos de texto brancos
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}