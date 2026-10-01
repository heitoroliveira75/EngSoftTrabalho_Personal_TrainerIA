import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS E CONTROLADORES
  // ===========================================================================
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // Função para validar e processar a troca de senha conectada ao FastAPI
  Future<void> _salvarSenha() async {
    final senhaAtual = _currentPassController.text.trim();
    final novaSenha = _newPassController.text.trim();
    final confirmarSenha = _confirmPassController.text.trim();

    // 1. Validação: Campos vazios
    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmarSenha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // 2. Validação: Comprimento mínimo
    if (novaSenha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha deve ter pelo menos 6 caracteres.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // 3. Validação: Senha igual à atual
    if (novaSenha == senhaAtual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha deve ser diferente da senha atual.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // 4. Validação: Senhas não coincidem
    if (novaSenha != confirmarSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha e a confirmação não coincidem!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    final email = ApiService().emailUsuarioAtual;

    final resposta = await ApiService().alterarSenha(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
      email: email.isNotEmpty ? email : null,
    );

    if (!mounted) return;

    setState(() => _carregando = false);

    if (resposta['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Senha alterada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      // Retorna para a tela de Perfil
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Erro ao alterar a senha.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = ApiService().nomeUsuarioAtual;
    final usuarioInicial = nome.isNotEmpty ? nome[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'ALTERAR SENHA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card Branco com os campos de input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF8A5CF5),
                    child: Text(
                      usuarioInicial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo 1: Senha Atual
                  _buildInputField(
                    label: 'Senha Atual',
                    controller: _currentPassController,
                    hintText: 'Digite a sua senha atual',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),

                  // Campo 2: Nova Senha
                  _buildInputField(
                    label: 'Nova Senha',
                    controller: _newPassController,
                    hintText: 'Digite a nova senha',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),

                  // Campo 3: Confirmar Senha
                  _buildInputField(
                    label: 'Confirmar Senha',
                    controller: _confirmPassController,
                    hintText: 'Confirme a nova senha',
                    isPassword: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3139),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _carregando ? null : _salvarSenha,
                child: _carregando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salvar',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar dos campos de texto com máscara e hintText
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2196F3),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          obscuringCharacter: '*',
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
