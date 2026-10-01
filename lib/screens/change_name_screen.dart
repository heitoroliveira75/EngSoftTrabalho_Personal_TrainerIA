import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ChangeNameScreen extends StatefulWidget {
  const ChangeNameScreen({super.key});

  @override
  State<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS
  // ===========================================================================
  late String nomeAtual;
  late TextEditingController currentNameController;
  late TextEditingController newNameController;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    nomeAtual = ApiService().nomeUsuarioAtual;
    currentNameController = TextEditingController(text: nomeAtual);
    newNameController = TextEditingController();
  }

  @override
  void dispose() {
    currentNameController.dispose();
    newNameController.dispose();
    super.dispose();
  }

  Future<void> _salvarNovoNome() async {
    final novoNome = newNameController.text.trim();

    if (novoNome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite o seu novo nome.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (novoNome.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O nome deve ter pelo menos 2 caracteres.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (novoNome.toLowerCase() == nomeAtual.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O novo nome deve ser diferente do nome atual.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    String? usuarioId = ApiService().idUsuarioAtual;
    if (usuarioId == null) {
      final resUser = await ApiService().obterUsuarioAtual();
      if (resUser['sucesso'] == true && resUser['usuario'] != null) {
        usuarioId = resUser['usuario']['id']?.toString();
      }
    }

    if (usuarioId == null) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão inválida. Faça login novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final resposta = await ApiService().editarPerfil(
      usuarioId,
      nome: novoNome,
    );

    if (!mounted) return;

    setState(() => _carregando = false);

    if (resposta['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Nome atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Erro ao atualizar o nome.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final letraAvatar = nomeAtual.isNotEmpty ? nomeAtual[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Seta e texto clicáveis para voltar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'ALTERAR NOME',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                      letraAvatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Nome Atual',
                    controller: currentNameController,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Novo Nome',
                    controller: newNameController,
                    hintText: 'Digite o seu novo nome',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                onPressed: _carregando ? null : _salvarNovoNome,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool enabled = true,
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
          enabled: enabled,
          obscureText: isPassword,
          obscuringCharacter: '*',
          style: TextStyle(
            color: enabled ? Colors.black87 : Colors.black54,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
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
