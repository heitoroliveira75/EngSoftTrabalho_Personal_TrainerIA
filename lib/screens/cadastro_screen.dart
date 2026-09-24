import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _executarCadastro() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmarSenha = _confirmarSenhaController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirmarSenha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (senha != confirmarSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter pelo menos 6 caracteres.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    final resposta = await ApiService().criarConta(
      nome: nome,
      email: email,
      senha: senha,
    );

    if (!mounted) return;

    setState(() {
      _carregando = false;
    });

    if (resposta['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Conta criada com sucesso! Faça login.'),
          backgroundColor: Colors.green,
        ),
      );
      // Volta para a tela de login
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Falha ao criar conta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Fundo escuro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título Cadastro
                const Text(
                  'Cadastro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 28),

                // Campo Nome Completo
                _buildInputField(
                  controller: _nomeController,
                  hintText: 'Nome Completo',
                ),

                const SizedBox(height: 14),

                // Campo E-mail
                _buildInputField(
                  controller: _emailController,
                  hintText: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 14),

                // Campo Senha
                _buildInputField(
                  controller: _senhaController,
                  hintText: 'Senha (mínimo 6 caracteres)',
                  obscureText: true,
                ),

                const SizedBox(height: 14),

                // Campo Confirme a senha
                _buildInputField(
                  controller: _confirmarSenhaController,
                  hintText: 'Confirme a senha',
                  obscureText: true,
                ),

                const SizedBox(height: 20),

                // Botão Continuar / Criar Conta
                ElevatedButton(
                  onPressed: _carregando ? null : _executarCadastro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF030712), // Preto / quase preto
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    elevation: 0,
                  ),
                  child: _carregando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Criar Conta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
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

                const SizedBox(height: 20),

                // Botão Continuar com Google
                _buildSocialButton(
                  text: 'Continuar com o Google',
                  icon: const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cadastro social em desenvolvimento.')),
                    );
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cadastro social em desenvolvimento.')),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Rodapé "Já possui uma conta? Faça login."
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já possui uma conta? ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Faça login.',
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
