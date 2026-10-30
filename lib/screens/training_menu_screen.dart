import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'criar_exercicio_screen.dart';
import 'dificuldade_treino_screen.dart';
import 'opcao_treinos_screen.dart';

class TrainingMenuScreen extends StatefulWidget {
  const TrainingMenuScreen({super.key});

  @override
  State<TrainingMenuScreen> createState() => _TrainingMenuScreenState();
}

class _TrainingMenuScreenState extends State<TrainingMenuScreen> {
  int _sequencia = 0;

  @override
  void initState() {
    super.initState();
    _carregarSequencia();
  }

  void _carregarSequencia() {
    setState(() {
      _sequencia = ApiService().sequenciaAtual;
    });

    final id = ApiService().idUsuarioAtual;
    if (id != null && id.isNotEmpty) {
      ApiService().verPontuacao(id).then((res) {
        if (mounted && res['sucesso'] == true) {
          setState(() {
            _sequencia = ApiService().sequenciaAtual;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double spacing = 35.0;

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
            'TREINO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            const Text(
              'O que vamos treinar hoje?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: spacing + 20),

            // 1. Card Meus Treinos
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OpcaoTreinosScreen(
                      dificuldadeFlag: 'meus_treinos',
                    ),
                  ),
                );
                _carregarSequencia();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF383B42),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 60,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Flexible(
                                child: Text(
                                  'Meus Treinos',
                                  style: TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF2196F3),
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Acesse seus treinos salvos e as suas rotinas personalizadas',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: spacing),

            // 2. Row com Criar Treinos e Treinos Padrões
            IntrinsicHeight( // este é para todos terem a mesma altura
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Criar Treinos
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CriarExercicioScreen(),
                          ),
                        );
                        _carregarSequencia();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 195),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF383B42),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Icon(
                                  Icons.add,
                                  size: 52,
                                  color: Color(0xFF00E676),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF00E676),
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Criar Treinos',
                                  style: TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Monte o seu treino do zero',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Card Treinos Padrões
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DificuldadeScreen(),
                          ),
                        );
                        _carregarSequencia();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 195),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF383B42),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Icon(
                                  Icons.star,
                                  size: 52,
                                  color: Color(0xFFFFB300),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFFFFB300),
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Treinos Padrões',
                                  style: TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Escolha um treino baseado na dificuldade',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: spacing),

            // 3. Card Sequência
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF383B42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 52, color: Color(0xFFFFB300)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Mantenha a sequência',
                                style: TextStyle(
                                  color: Color(0xFF8A5CF5),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_sequencia > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8A5CF5)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_sequencia dias 🔥',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Conclua um treino hoje para manter a sua sequência e ganhar mais pontos.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
