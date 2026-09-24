import 'package:flutter/material.dart';

class ChangeNameScreen extends StatefulWidget {
  const ChangeNameScreen({super.key});

  @override
  State<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS
  // ===========================================================================
  String nomeAtual = 'João Pedro Almeida';

  late TextEditingController currentNameController;
  late TextEditingController newNameController;

  @override
  void initState() {
    super.initState();
    currentNameController = TextEditingController(text: nomeAtual);
    newNameController = TextEditingController();
  }

  @override
  void dispose() {
    currentNameController.dispose();
    newNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Seta e texto clicáveis para voltar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('ALTERAR NOME'),
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
                      nomeAtual.isNotEmpty ? nomeAtual[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 32),
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
                onPressed: () {
                  // Lógica para guardar no banco de dados e voltar à tela anterior
                  Navigator.pop(context);
                },
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool enabled = true,
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
            enabled: enabled,
            style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF90CAF9),
                fontSize: 13,
              ),
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
              disabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black38),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
