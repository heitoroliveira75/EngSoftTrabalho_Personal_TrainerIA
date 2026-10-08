import 'package:flutter/material.dart';

import 'treino_selecionado_screen.dart';

// MOCK EXPANDIDO DE DADOS POR DIFICULDADE
final Map<String, List<Map<String, dynamic>>> bancoDeTreinos = {
  'iniciante': [
    {
      'id': '1',
      'titulo': 'Corpo completo A',
      'dificuldade': 'Iniciante',
      'exerciciosCount': 8,
      'duracaoMinutos': 40,
      'pontosTotais': 200,
      'corTema': const Color(0xFF00E676),
      'exercicios': [
        {'nome': 'Polichinelo', 'series': 3, 'repeticoes': 12, 'pontos': 20},
        {
          'nome': 'Agachamento Livre',
          'series': 3,
          'repeticoes': 12,
          'pontos': 20,
        },
        {
          'nome': 'Flexão com Joelhos',
          'series': 3,
          'repeticoes': 10,
          'pontos': 20,
        },
        {
          'nome': 'Abdominal Supra',
          'series': 3,
          'repeticoes': 15,
          'pontos': 20,
        },
        {
          'nome': 'Prancha Abdominal',
          'series': 3,
          'repeticoes': 30,
          'pontos': 20,
        },
        {
          'nome': 'Elevação Pélvica',
          'series': 3,
          'repeticoes': 12,
          'pontos': 20,
        },
        {'nome': 'Passada Parada', 'series': 3, 'repeticoes': 10, 'pontos': 20},
        {
          'nome': 'Polichinelo Inverso',
          'series': 3,
          'repeticoes': 12,
          'pontos': 20,
        },
      ],
    },
    {
      'id': '2',
      'titulo': 'Membros Inferiores & Core',
      'dificuldade': 'Iniciante',
      'exerciciosCount': 5,
      'duracaoMinutos': 25,
      'pontosTotais': 140,
      'corTema': const Color(0xFF00E676),
      'exercicios': [
        {
          'nome': 'Agachamento Isométrico',
          'series': 3,
          'repeticoes': 30,
          'pontos': 25,
        },
        {
          'nome': 'Afundo Alternado',
          'series': 3,
          'repeticoes': 10,
          'pontos': 25,
        },
        {
          'nome': 'Abdominal Infra',
          'series': 3,
          'repeticoes': 12,
          'pontos': 30,
        },
        {'nome': 'Ponte Glúteos', 'series': 3, 'repeticoes': 15, 'pontos': 30},
        {
          'nome': 'Elevação de Panturrilha',
          'series': 3,
          'repeticoes': 20,
          'pontos': 30,
        },
      ],
    },
    {
      'id': '3',
      'titulo': 'Mobilidade e Alongamento',
      'dificuldade': 'Iniciante',
      'exerciciosCount': 6,
      'duracaoMinutos': 20,
      'pontosTotais': 100,
      'corTema': const Color(0xFF00E676),
      'exercicios': [
        {
          'nome': 'Rotação de Tronco',
          'series': 2,
          'repeticoes': 15,
          'pontos': 15,
        },
        {'nome': 'Gato-Camelo', 'series': 3, 'repeticoes': 10, 'pontos': 15},
        {
          'nome': 'Alongamento de Posteriores',
          'series': 2,
          'repeticoes': 30,
          'pontos': 20,
        },
        {
          'nome': 'Alongamento de Quadríceps',
          'series': 2,
          'repeticoes': 30,
          'pontos': 20,
        },
        {
          'nome': 'Rotação de Ombros',
          'series': 2,
          'repeticoes': 12,
          'pontos': 15,
        },
        {
          'nome': 'Postura da Criança',
          'series': 2,
          'repeticoes': 45,
          'pontos': 15,
        },
      ],
    },
  ],
  'intermediario': [
    {
      'id': '4',
      'titulo': 'Superiores & HIIT',
      'dificuldade': 'Intermediário',
      'exerciciosCount': 7,
      'duracaoMinutos': 45,
      'pontosTotais': 280,
      'corTema': const Color(0xFF29B6F6),
      'exercicios': [
        {
          'nome': 'Flexão Tradicional',
          'series': 4,
          'repeticoes': 12,
          'pontos': 35,
        },
        {
          'nome': 'Tríceps no Banco',
          'series': 4,
          'repeticoes': 12,
          'pontos': 35,
        },
        {
          'nome': 'Mountain Climber',
          'series': 4,
          'repeticoes': 20,
          'pontos': 40,
        },
        {
          'nome': 'Desenvolvimento Halteres',
          'series': 4,
          'repeticoes': 10,
          'pontos': 40,
        },
        {'nome': 'Remada Curvada', 'series': 4, 'repeticoes': 12, 'pontos': 40},
        {
          'nome': 'Abdominal Remador',
          'series': 4,
          'repeticoes': 15,
          'pontos': 45,
        },
        {
          'nome': 'Prancha Dinâmica',
          'series': 3,
          'repeticoes': 40,
          'pontos': 45,
        },
      ],
    },
    {
      'id': '5',
      'titulo': 'Pernas & Glúteos Intenso',
      'dificuldade': 'Intermediário',
      'exerciciosCount': 6,
      'duracaoMinutos': 35,
      'pontosTotais': 250,
      'corTema': const Color(0xFF29B6F6),
      'exercicios': [
        {
          'nome': 'Agachamento Búlgaro',
          'series': 3,
          'repeticoes': 10,
          'pontos': 40,
        },
        {
          'nome': 'Agachamento Sumô',
          'series': 4,
          'repeticoes': 12,
          'pontos': 40,
        },
        {
          'nome': 'Stiff com Halteres',
          'series': 4,
          'repeticoes': 12,
          'pontos': 40,
        },
        {
          'nome': 'Saltos Vertical na Caixa',
          'series': 3,
          'repeticoes': 10,
          'pontos': 40,
        },
        {
          'nome': 'Elevação Pélvica Unilateral',
          'series': 3,
          'repeticoes': 12,
          'pontos': 45,
        },
        {
          'nome': 'Cadeira Flexora',
          'series': 3,
          'repeticoes': 15,
          'pontos': 45,
        },
      ],
    },
    {
      'id': '6',
      'titulo': 'Desafio Core & Cardio',
      'dificuldade': 'Intermediário',
      'exerciciosCount': 5,
      'duracaoMinutos': 30,
      'pontosTotais': 220,
      'corTema': const Color(0xFF29B6F6),
      'exercicios': [
        {'nome': 'Russian Twist', 'series': 4, 'repeticoes': 20, 'pontos': 40},
        {
          'nome': 'Prancha Lateral com Elevação',
          'series': 3,
          'repeticoes': 10,
          'pontos': 45,
        },
        {
          'nome': 'Polichinelo com Carga',
          'series': 4,
          'repeticoes': 20,
          'pontos': 45,
        },
        {
          'nome': 'Bicicleta Abdominal',
          'series': 4,
          'repeticoes': 20,
          'pontos': 45,
        },
        {
          'nome': 'Corrida Estacionária',
          'series': 4,
          'repeticoes': 45,
          'pontos': 45,
        },
      ],
    },
  ],
  'avancado': [
    {
      'id': '7',
      'titulo': 'Full Body Extreme',
      'dificuldade': 'Avançado',
      'exerciciosCount': 8,
      'duracaoMinutos': 55,
      'pontosTotais': 480,
      'corTema': const Color(0xFF9E7AFF),
      'exercicios': [
        {
          'nome': 'Burpee Completo com Flexão',
          'series': 4,
          'repeticoes': 15,
          'pontos': 60,
        },
        {
          'nome': 'Agachamento com Salto',
          'series': 4,
          'repeticoes': 20,
          'pontos': 60,
        },
        {
          'nome': 'Flexão Declinada',
          'series': 4,
          'repeticoes': 15,
          'pontos': 60,
        },
        {
          'nome': 'Pistol Squat (Cada Perna)',
          'series': 3,
          'repeticoes': 8,
          'pontos': 60,
        },
        {
          'nome': 'Barra Fixa Pronada',
          'series': 4,
          'repeticoes': 10,
          'pontos': 60,
        },
        {
          'nome': 'Abdominal Canivete',
          'series': 4,
          'repeticoes': 15,
          'pontos': 60,
        },
        {
          'nome': 'Prancha com Carga',
          'series': 4,
          'repeticoes': 60,
          'pontos': 60,
        },
        {'nome': 'Sprawl Cardio', 'series': 4, 'repeticoes': 15, 'pontos': 60},
      ],
    },
    {
      'id': '8',
      'titulo': 'Calistenia de Alta Performance',
      'dificuldade': 'Avançado',
      'exerciciosCount': 6,
      'duracaoMinutos': 50,
      'pontosTotais': 400,
      'corTema': const Color(0xFF9E7AFF),
      'exercicios': [
        {
          'nome': 'Flexão Diamante',
          'series': 4,
          'repeticoes': 15,
          'pontos': 65,
        },
        {
          'nome': 'Muscle Up / Flexão na Barra',
          'series': 4,
          'repeticoes': 6,
          'pontos': 70,
        },
        {
          'nome': 'Flexão Pseudo-Planoche',
          'series': 4,
          'repeticoes': 10,
          'pontos': 65,
        },
        {
          'nome': 'Agachamento Búlgaro Salto',
          'series': 4,
          'repeticoes': 12,
          'pontos': 65,
        },
        {
          'nome': 'L-Sit na Paralela',
          'series': 4,
          'repeticoes': 20,
          'pontos': 70,
        },
        {
          'nome': 'Dragon Flag Flexion',
          'series': 3,
          'repeticoes': 8,
          'pontos': 65,
        },
      ],
    },
  ],
};

class OpcaoTreinosScreen extends StatelessWidget {
  final String dificuldadeFlag;

  const OpcaoTreinosScreen({super.key, required this.dificuldadeFlag});

  Color get _corTema {
    switch (dificuldadeFlag) {
      case 'iniciante':
        return const Color(0xFF00E676);
      case 'intermediario':
        return const Color(0xFF29B6F6);
      case 'avancado':
        return const Color(0xFF9E7AFF);
      default:
        return const Color(0xFF00E676);
    }
  }

  String get _tituloDificuldade {
    switch (dificuldadeFlag) {
      case 'iniciante':
        return 'INICIANTE';
      case 'intermediario':
        return 'INTERMEDIÁRIO';
      case 'avancado':
        return 'AVANÇADO';
      default:
        return 'TREINOS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> treinosDoNivel =
        bancoDeTreinos[dificuldadeFlag] ?? [];

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
      body: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text(
              _tituloDificuldade,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: treinosDoNivel.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum treino disponível para este nível.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: treinosDoNivel.length,
                    itemBuilder: (context, index) {
                      final treino = treinosDoNivel[index];
                      final Color corCard = treino['corTema'] ?? _corTema;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TreinoSelecionadoScreen(treinoData: treino),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: corCard, width: 1.8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        treino['titulo'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.star_border,
                                        color: Colors.grey,
                                        size: 28,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                                Text(
                                  '${treino['exerciciosCount']} exercícios, ${treino['duracaoMinutos']} minutos',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.grey, height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '+${treino['pontosTotais']} pts',
                                      style: TextStyle(
                                        color: corCard,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      treino['dificuldade'],
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
