import 'package:flutter/material.dart';

void main() {
  runApp(const MeuAppCadastro());
}

class MeuAppCadastro extends StatelessWidget {
  const MeuAppCadastro({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CadastroScreen(),
    );
  }
}

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Fundo escuro
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
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

                // Campo Usuário
                _buildInputField(
                  controller: _usuarioController,
                  hintText: 'Usuário',
                ),

                const SizedBox(height: 16),

                // Campo Senha
                _buildInputField(
                  controller: _senhaController,
                  hintText: 'Senha',
                  obscureText: true,
                ),

                const SizedBox(height: 16),

                // Botão Continuar
                ElevatedButton(
                  onPressed: () {
                    debugPrint('Continuar clicado: ${_usuarioController.text}');
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

                const SizedBox(height: 14),

                // Link "Esqueceu a senha?"
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('Esqueceu a senha clicado');
                    },
                    child: const Text(
                      'Esqueceu a senha?',
                      style: TextStyle(
                        color: Color(0xFFE91E63), // Rosa vibrante
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divisor "ou"
                Row(
                  children: const [
                    Expanded(
                      child: Divider(
                        color: Colors.white38,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white38,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Botão Continuar com Google
                _buildSocialButton(
                  text: 'Continuar com o Google',
                  icon: const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  onTap: () {
                    debugPrint('Google login');
                  },
                ),

                const SizedBox(height: 12),

                // Botão Continuar com Apple
                _buildSocialButton(
                  text: 'Continuar com a Apple',
                  icon: const Icon(
                    Icons.apple,
                    color: Colors.black,
                    size: 22,
                  ),
                  onTap: () {
                    debugPrint('Apple login');
                  },
                ),

                const SizedBox(height: 36),

                // Rodapé "Não possui uma conta? Crie uma conta"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Não possui uma conta? ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        debugPrint('Crie uma conta clicado');
                      },
                      child: const Text(
                        'Crie uma conta',
                        style: TextStyle(
                          color: Color(0xFFE91E63), // Rosa vibrante
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
    );
  }

  // Widget auxiliar para os campos de texto brancos
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Widget auxiliar para os botões sociais brancos
  Widget _buildSocialButton({
    required String text,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}