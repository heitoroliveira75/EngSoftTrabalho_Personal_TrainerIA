import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TreinosScreen extends StatefulWidget {
  const TreinosScreen({super.key});

  @override
  State<TreinosScreen> createState() => _TreinosScreenState();
}

class _TreinosScreenState extends State<TreinosScreen> {
  bool _carregando = true;
  List<dynamic> _treinos = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  Future<void> _carregarTreinos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resposta = await ApiService().verTreinosPremontados();

    if (!mounted) return;

    setState(() {
      _carregando = false;
      if (resposta['sucesso'] == true) {
        _treinos = resposta['treinos'] ?? [];
      } else {
        _erro = resposta['mensagem'] ?? 'Erro ao carregar treinos.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030712),
        elevation: 0,
        title: const Text(
          'Treinos Disponíveis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarTreinos,
          ),
        ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _carregarTreinos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _treinos.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum treino cadastrado no momento.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _treinos.length,
                      itemBuilder: (context, index) {
                        final treino = _treinos[index];
                        final exercicios = treino['treino_exercicios'] as List<dynamic>? ?? [];

                        return Card(
                          color: const Color(0xFF1E232A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF00E676),
                              child: Icon(Icons.fitness_center, color: Colors.black),
                            ),
                            title: Text(
                              treino['nome'] ?? 'Treino Sem Nome',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              treino['descricao'] != null && (treino['descricao'] as String).isNotEmpty
                                  ? treino['descricao']
                                  : '${exercicios.length} exercício(s)',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            iconColor: const Color(0xFF00E676),
                            collapsedIconColor: Colors.white54,
                            children: [
                              const Divider(color: Colors.white12),
                              if (exercicios.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Nenhum exercício vinculado a este treino.',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                )
                              else
                                ...exercicios.map((te) {
                                  final exInfo = te['exercicios'] as Map<String, dynamic>? ?? {};
                                  final nomeEx = exInfo['nome'] ?? 'Exercício';
                                  final grupo = exInfo['grupo_muscular'] ?? '';
                                  final series = te['series'] ?? 3;
                                  final reps = te['repeticoes'] ?? 10;
                                  final ordem = te['ordem'] ?? 1;

                                  return ListTile(
                                    leading: Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '$ordem',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      nomeEx,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      grupo.isNotEmpty ? 'Grupo: $grupo' : '',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '${series}x $reps reps',
                                      style: const TextStyle(
                                        color: Color(0xFF00E676),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E676),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 20),
                                    label: const Text(
                                      'Concluir Treino (+50 pts)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    onPressed: () => _concluirTreino(treino['nome'] ?? 'Treino'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Future<void> _concluirTreino(String nomeTreino) async {
    final usuarioId = ApiService().idUsuarioAtual;
    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para pontuar nos treinos.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    const pontosGanhos = 50;
    final res = await ApiService().adicionarPontuacaoDiaria(
      usuarioId: usuarioId,
      pontos: pontosGanhos,
    );

    if (!mounted) return;

    if (res['sucesso'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E232A),
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text('Treino Concluído!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Parabéns! Você completou "$nomeTreino" e ganhou +$pontosGanhos pontos hoje!\n\n'
            'Pontos Hoje: ${res['pontuacao_diaria'] ?? 0} pts\n'
            'Pontos Semana: ${res['pontuacao_semanal'] ?? 0} pts\n'
            'Pontos Totais: ${res['pontuacao_total'] ?? 0} pts\n'
            'Sequência: ${res['sequencia'] ?? ApiService().sequenciaAtual} ${((res['sequencia'] ?? ApiService().sequenciaAtual) == 1) ? "dia" : "dias"} 🔥',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensagem'] ?? 'Erro ao adicionar pontos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}


