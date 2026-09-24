import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RedefinirSenhaScreen extends StatefulWidget {
  final String? emailPreenchido;

  const RedefinirSenhaScreen({super.key, this.emailPreenchido});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  late final TextEditingController _emailController;
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmeSenhaController = TextEditingController();
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.emailPreenchido ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmeSenhaController.dispose();
    super.dispose();
  }

  Future<void> _executarRedefinicao() async {
    final email = _emailController.text.trim();
    final codigo = _codigoController.text.trim();
    final novaSenha = _novaSenhaController.text.trim();
    final confirmeSenha = _confirmeSenhaController.text.trim();

    if (codigo.isEmpty || novaSenha.isEmpty || confirmeSenha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o código e a nova senha.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (novaSenha != confirmeSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não conferem.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (novaSenha.length < 6) {
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

    final resposta = await ApiService().redefinirSenha(
      email: email.isNotEmpty ? email : null,
      codigo: codigo,
      novaSenha: novaSenha,
    );

    if (!mounted) return;

    setState(() {
      _carregando = false;
    });

    if (resposta['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Senha redefinida com sucesso! Faça login.'),
          backgroundColor: Colors.green,
        ),
      );
      // Retorna para o login desempilhando as telas de recuperação
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Falha ao redefinir senha.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Fundo escuro padrão
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
                // Título
                const Text(
                  'Redefinir Senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Texto explicativo central
                const Text(
                  'Informe o código de segurança\n'
                  'enviado ao seu e-mail e digite qual\n'
                  'será sua nova senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.45,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 36),

                // Campo Código
                _buildInputField(
                  controller: _codigoController,
                  hintText: 'Código de verificação',
                  keyboardType: TextInputType.text,
                ),

                const SizedBox(height: 16),

                // Campo Nova senha
                _buildInputField(
                  controller: _novaSenhaController,
                  hintText: 'Nova senha (mínimo 6 caracteres)',
                  obscureText: true,
                ),

                const SizedBox(height: 16),

                // Campo Confirme a senha
                _buildInputField(
                  controller: _confirmeSenhaController,
                  hintText: 'Confirme a nova senha',
                  obscureText: true,
                ),

                const SizedBox(height: 20),

                // Botão Continuar
                ElevatedButton(
                  onPressed: _carregando ? null : _executarRedefinicao,
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
                          'Salvar Nova Senha',
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
