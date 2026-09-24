import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS E CONTROLADORES
  // ===========================================================================
  String usuarioInicial = 'J';

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // Função para validar e processar a troca de senha
  void _salvarSenha() {
    String senhaAtual = _currentPassController.text;
    String novaSenha = _newPassController.text;
    String confirmarSenha = _confirmPassController.text;

    // 1. Validação: Campos vazios
    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmarSenha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. Validação: Senhas não coincidem
    if (novaSenha != confirmarSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha e a confirmação não coincidem!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 3. Sucesso (Aqui você enviará os dados para o seu Banco de Dados/API)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha alterada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );

    // Retorna para a tela de Perfil
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'ALTERAR SENHA',
            style: TextStyle(fontWeight: FontWeight.bold),
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
                      style: const TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo 1: Senha Atual
                  _buildInputField(
                    label: 'Senha Atual',
                    controller: _currentPassController,
                    hintText: 'Digite a sua senha',
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
                onPressed: _salvarSenha,
                child: const Text(
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            obscuringCharacter: '*', // Define o caractere de ocultação como '*'
            style: const TextStyle(color: Color(0xFF2196F3), fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black54),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2196F3)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
