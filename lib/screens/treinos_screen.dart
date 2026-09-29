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
                                }).toList(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
