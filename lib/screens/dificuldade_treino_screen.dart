import 'package:flutter/material.dart';

import 'opcao_treinos_screen.dart';

class DificuldadeScreen extends StatelessWidget {
  const DificuldadeScreen({super.key});

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
            const SizedBox(height: 12),
            const Text(
              'Qual dificuldade de treino?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 80),

            _buildCardDificuldade(
              context,
              titulo: 'INICIANTE',
              descricao: 'Para aqueles que querem começar a se exercitar',
              corTema: const Color(0xFF00E676),
              flagDificuldade: 'iniciante',
            ),
            const SizedBox(height: 40),

            _buildCardDificuldade(
              context,
              titulo: 'INTERMEDIÁRIO',
              descricao: 'Quem já possui experiência e quer melhorar',
              corTema: const Color(0xFF29B6F6),
              flagDificuldade: 'intermediario',
            ),
            const SizedBox(height: 40),

            _buildCardDificuldade(
              context,
              titulo: 'AVANÇADO',
              descricao:
                  'Recomendado apenas para quem busca o máximo de desempenho',
              corTema: const Color(0xFF9E7AFF),
              flagDificuldade: 'avancado',
            ),

            const Spacer(),

            _buildSequenceCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDificuldade(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required Color corTema,
    required String flagDificuldade,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OpcaoTreinosScreen(dificuldadeFlag: flagDificuldade),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: corTema, width: 1.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: corTema,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
