import 'package:flutter/material.dart';

class DificuldadeTreinoScreen extends StatelessWidget {
  const DificuldadeTreinoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TREINO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Qual dificuldade de treino?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 80), //espaçamento entre título e botão 1
            // Card Iniciante (Borda Verde)
            _buildDificuldadeCard(
              context,
              titulo: 'INICIANTE',
              descricao: 'Para aqueles que querem começar a se exercitar',
              corBorda: const Color(0xFF00E676),
              onTap: () {
                // Ação ao selecionar Iniciante
              },
            ),

            const SizedBox(height: 40), // espaço entre b1 e b2
            // Card Intermediário (Borda Azul)
            _buildDificuldadeCard(
              context,
              titulo: 'INTERMEDIÁRIO',
              descricao: 'Quem já possui experiência e quer melhorar',
              corBorda: const Color(0xFF29B6F6),
              onTap: () {
                // Ação ao selecionar Intermediário
              },
            ),

            const SizedBox(height: 40), //espaçamento entre b2 eb3
            // Card Avançado (Borda Roxa/Neon)
            _buildDificuldadeCard(
              context,
              titulo: 'AVANÇADO',
              descricao:
                  'Recomendado apenas para quem busca o máximo de desempenho',
              corBorda: const Color(0xFF9E7AFF),
              onTap: () {
                // Ação ao selecionar Avançado
              },
            ),

            const Spacer(),

            // Card informativo de sequência
            _buildSequenceCard(),
            const SizedBox(
              height: 200,
            ), //espaçameno entre card final e o fim do celular
          ],
        ),
      ),
    );
  }

  Widget _buildDificuldadeCard(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required Color corBorda,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: corBorda, width: 1.8),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: corBorda,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSequenceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mantenha a sequência',
                  style: TextStyle(
                    color: Color(0xFF9E7AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Conclua um treino hoje para manter a sua sequência e ganhar mais pontos',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
