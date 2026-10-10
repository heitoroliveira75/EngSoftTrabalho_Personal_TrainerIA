import 'package:flutter/material.dart';
import '../services/api_service.dart';

class criar_exercicio_screen extends StatefulWidget {
  const criar_exercicio_screen({super.key});

  @override
  State<criar_exercicio_screen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<criar_exercicio_screen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS (Substitua no futuro pelos dados vindos do banco de dados)
  // ===========================================================================
  int pontosTotais = 1850;
  int pontosSemana = 250;
  int maiorSequencia = 6;
  int sequenciaAtual = 2;
  int pontosHoje = 150;
  int metaHoje = 200;
  final TextEditingController _nomeexercicio = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Seta de voltar + texto "PERFIL" clicáveis
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('TREINOS'),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            const SizedBox(height: 36),

            // Campo E-mail / Usuário
            _buildInputField(
              controller: _nomeexercicio,
              hintText: 'Dê um nome ao seu treino',
              keyboardType: TextInputType.text,
            ),
            
            const SizedBox(height: 36),

            
            // 1. Card Meta de Hoje
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3139),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Meta de Hoje',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '$pontosHoje/$metaHoje pts',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: metaHoje > 0
                          ? (pontosHoje / metaHoje).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 16,
                      backgroundColor: Colors.grey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            //espaçamento
            //const SizedBox(height: 32),

          ],
        ),
      ),
    );
  }


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
        hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
        filled: true,
        fillColor: Color(0xFF2D3139),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

}
