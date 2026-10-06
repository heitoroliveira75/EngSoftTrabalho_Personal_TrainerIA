import 'package:flutter/material.dart';

import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS (Substitua no futuro pelos dados vindos do banco de dados)
  // ===========================================================================
  int pontosTotais = 1850;
  int pontosSemana = 250;
  int maiorSequencia = 6;
  int sequenciaAtual = 2;
  int pontosHoje = 150;
  int metaHoje = 200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'HOME',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          // Ícone de perfil que navega para a tela de Perfil
          IconButton(
            icon: const Icon(Icons.account_circle, size: 36),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Card Pontos Totais
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Pontos Totais',
                    style: TextStyle(
                      color: Color(0xFF8A5CF5),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$pontosTotais pts',
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+$pontosSemana pts essa semana',
                    style: const TextStyle(
                      color: Color(0xFF64B5F6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            //espaçamento
            const SizedBox(height: 32),

            // 2. Os 3 Cards de Métricas (com Altura Igual)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      value: '$maiorSequencia',
                      label: 'Maior\nSequência',
                      labelColor: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.bolt,
                      iconColor: Colors.amberAccent,
                      value: '$sequenciaAtual',
                      label: 'Sequência',
                      labelColor: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.emoji_events,
                      iconColor: Colors.amber,
                      value: '$pontosHoje',
                      label: 'Pts Hoje',
                      labelColor: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),

            //espaçamento
            const SizedBox(height: 32),

            // 3. Card Meta de Hoje
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3139),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meta de Hoje',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
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
            const SizedBox(height: 32),

            // 4. Botão Hora de Treinar
            InkWell(
              onTap: () {
                // Ação para iniciar o treino
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3139),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: Color(0xFF00E676),
                    ),
                    const SizedBox(width: 16),
                    Container(height: 50, width: 2, color: Colors.grey),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora de',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Treinar',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3139),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment
            .spaceBetween, // Distribui o conteúdo verticalmente
        children: [
          Icon(icon, size: 48, color: iconColor),
          Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: labelColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
