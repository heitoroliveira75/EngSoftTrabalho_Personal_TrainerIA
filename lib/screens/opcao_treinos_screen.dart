import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'treino_selecionado_screen.dart';
import 'criar_exercicio_screen.dart';

class OpcaoTreinosScreen extends StatefulWidget {
  final String dificuldadeFlag;

  const OpcaoTreinosScreen({super.key, required this.dificuldadeFlag});

  @override
  State<OpcaoTreinosScreen> createState() => _OpcaoTreinosScreenState();
}

class _OpcaoTreinosScreenState extends State<OpcaoTreinosScreen> {
  bool _carregando = true;
  List<Map<String, dynamic>> _listaTreinos = [];

  Color get _corTema {
    return const Color(0xFF00E676);
  }

  String get _tituloDificuldade {
    switch (widget.dificuldadeFlag) {
      case 'iniciante':
        return 'INICIANTE';
      case 'intermediario':
        return 'INTERMEDIÁRIO';
      case 'avancado':
        return 'AVANÇADO';
      case 'meus_treinos':
        return 'MEUS TREINOS';
      default:
        return 'TREINOS';
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  Future<void> _carregarTreinos() async {
    setState(() => _carregando = true);

    try {
      if (widget.dificuldadeFlag == 'meus_treinos') {
        // --- 1. CARREGA EXCLUSIVAMENTE OS TREINOS DO USUÁRIO ---
        final idUsuario = ApiService().idUsuarioAtual;
        final res = await ApiService().listarTreinosUsuario(idUsuario);

        if (!mounted) return;

        if (res['sucesso'] == true &&
            res['treinos'] is List &&
            (res['treinos'] as List).isNotEmpty) {
          final List treinosRaw = res['treinos'];
          final List<Map<String, dynamic>> convertidos = [];

          for (final t in treinosRaw) {
            final List<Map<String, dynamic>> exerciciosMapeados = [];

            if (t['exercicios'] is List &&
                (t['exercicios'] as List).isNotEmpty) {
              for (final ex in t['exercicios']) {
                if (ex is Map) {
                  final series = ex['series'] ?? 3;
                  final reps = ex['repeticoes'] ?? 10;
                  final pontos =
                      ex['pontos'] ??
                      ex['pontos_totais'] ??
                      ((series is int) ? series * 15 : 45);
                  exerciciosMapeados.add({
                    'id':
                        ex['id']?.toString() ??
                        ex['exercicio_id']?.toString() ??
                        '1',
                    'nome': ex['nome']?.toString() ?? 'Exercício',
                    'series': series,
                    'repeticoes': reps,
                    'pontos': pontos,
                    'pontos_totais': pontos,
                  });
                }
              }
            } else if (t['treino_exercicios'] is List &&
                (t['treino_exercicios'] as List).isNotEmpty) {
              for (final te in (t['treino_exercicios'] as List)) {
                if (te is Map) {
                  final exInfo =
                      te['exercicios'] as Map<String, dynamic>? ?? {};
                  final nomeEx = exInfo['nome'] ?? te['nome'] ?? 'Exercício';
                  final series = te['series'] ?? 3;
                  final reps = te['repeticoes'] ?? 10;
                  final pontos = (series is int) ? series * 15 : 45;
                  exerciciosMapeados.add({
                    'id':
                        te['exercicio_id']?.toString() ??
                        te['id']?.toString() ??
                        '1',
                    'nome': nomeEx.toString(),
                    'series': series,
                    'repeticoes': reps,
                    'pontos': pontos,
                    'pontos_totais': pontos,
                  });
                }
              }
            }

            final totalPontos = exerciciosMapeados.fold<int>(
              0,
              (soma, item) => soma + ((item['pontos'] as num?)?.toInt() ?? 0),
            );

            final duracao = exerciciosMapeados.isNotEmpty
                ? exerciciosMapeados.length * 5
                : ((t['duracaoMinutos'] as num?)?.toInt() ??
                      (t['duracao_minutos'] as num?)?.toInt() ??
                      20);

            final pontosTreino = totalPontos > 0
                ? totalPontos
                : ((t['pontosTotais'] as num?)?.toInt() ??
                      (t['pontos_totais'] as num?)?.toInt() ??
                      150);

            convertidos.add({
              'id': t['id'].toString(),
              'idSalvo': t['id'].toString(),
              'salvo': true,
              'ehMeusTreinos': true,
              'titulo': t['nome'] ?? t['titulo'] ?? 'Treino Personalizado',
              'dificuldade': t['dificuldade'] ?? 'Personalizado',
              'exerciciosCount': exerciciosMapeados.length,
              'duracaoMinutos': duracao,
              'pontosTotais': pontosTreino,
              'corTema': const Color(0xFF00E676),
              'exercicios': exerciciosMapeados,
            });
          }

          if (mounted) setState(() => _listaTreinos = convertidos);
        } else {
          if (mounted) setState(() => _listaTreinos = []);
        }
      } else {
        // --- 2. CARREGA OS TREINOS POR DIFICULDADE (INICIANTE, INTERMEDIÁRIO, AVANÇADO) ---
        final idUsuario = ApiService().idUsuarioAtual;
        final Future<Map<String, dynamic>> reqMeusTreinos = ApiService()
            .listarTreinosUsuario(idUsuario);
        final Future<Map<String, dynamic>> reqDificuldade = ApiService()
            .obterTreinosPorDificuldade(widget.dificuldadeFlag);

        final resultados = await Future.wait([reqDificuldade, reqMeusTreinos]);
        final res = resultados[0];
        final resMeusTreinos = resultados[1];

        if (!mounted) return;

        final Map<String, String> salvosPorTitulo = {};
        if (resMeusTreinos['sucesso'] == true &&
            resMeusTreinos['treinos'] is List) {
          for (final t in resMeusTreinos['treinos']) {
            if (t is Map) {
              final nome = (t['nome'] ?? t['titulo'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              if (nome.isNotEmpty && t['id'] != null) {
                salvosPorTitulo[nome] = t['id'].toString();
              }
            }
          }
        }

        if (res['sucesso'] == true &&
            res['treinos'] is List &&
            (res['treinos'] as List).isNotEmpty) {
          final List raw = res['treinos'];
          final List<Map<String, dynamic>> list = [];

          for (final item in raw) {
            final titulo = (item['titulo'] ?? item['nome'] ?? 'Treino')
                .toString();
            final idSalvo = salvosPorTitulo[titulo.trim().toLowerCase()];
            final bool estaSalvo = idSalvo != null;

            list.add({
              'id': item['id']?.toString() ?? '',
              'idSalvo': idSalvo,
              'salvo': estaSalvo,
              'titulo': titulo,
              'dificuldade': item['dificuldade'] ?? _tituloDificuldade,
              'exerciciosCount':
                  item['exerciciosCount'] ??
                  (item['exercicios'] as List?)?.length ??
                  0,
              'duracaoMinutos':
                  item['duracaoMinutos'] ?? item['duracao_minutos'] ?? 30,
              'pontosTotais':
                  item['pontosTotais'] ?? item['pontos_totais'] ?? 200,
              'corTema': const Color(0xFF00E676),
              'exercicios': item['exercicios'] ?? [],
            });
          }

          if (mounted) setState(() => _listaTreinos = list);
        } else {
          if (mounted) setState(() => _listaTreinos = []);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar treinos: $e');
      if (mounted) setState(() => _listaTreinos = []);
    } finally {
      // ✅ Garante que o loading sempre encerra, mesmo com falha ou lista vazia
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _aoClicarEstrela(Map<String, dynamic> treino) async {
    if (treino['salvando'] == true) return;

    final bool jaSalvo = treino['salvo'] == true;

    if (jaSalvo) {
      // Pop-up de confirmação antes de remover
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E232A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Remover Treino?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Deseja realmente remover o treino "${treino['titulo'] ?? 'Treino'}" dos Meus Treinos?\n\nEle deixará de constar na sua lista de treinos.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Remover',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      setState(() => treino['salvando'] = true);

      try {
        final idParaExcluir =
            treino['idSalvo']?.toString() ?? treino['id']?.toString();
        if (idParaExcluir != null && idParaExcluir.isNotEmpty) {
          await ApiService().excluirTreino(idParaExcluir);
        }

        if (mounted) {
          setState(() {
            treino['salvando'] = false;
            treino['salvo'] = false;
            treino['idSalvo'] = null;
            if (widget.dificuldadeFlag == 'meus_treinos') {
              _listaTreinos.remove(treino);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino removido dos Meus Treinos com sucesso!'),
              backgroundColor: Color(0xFF00E676),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => treino['salvando'] = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover treino: $e'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Salvar nos Meus Treinos
      setState(() => treino['salvando'] = true);
      final idUsuario = ApiService().idUsuarioAtual;
      final exercicios = (treino['exercicios'] as List? ?? [])
          .map(
            (e) => {
              'exercicio_id': e['exercicio_id'] ?? e['id'] ?? 1,
              'nome': e['nome'] ?? 'Exercício',
              'series': e['series'] ?? 3,
              'repeticoes': e['repeticoes'] ?? 10,
              'pontos': e['pontos'] ?? e['pontos_totais'] ?? 20,
              'pontos_totais': e['pontos_totais'] ?? e['pontos'] ?? 20,
            },
          )
          .toList();

      try {
        final res = await ApiService().criarTreino(
          usuarioId: idUsuario,
          nome: treino['titulo'] ?? 'Treino',
          descricao:
              'Treino salvo dos treinos ${treino['dificuldade'] ?? widget.dificuldadeFlag}',
          dificuldade: treino['dificuldade']?.toString() ?? _tituloDificuldade,
          duracaoMinutos: (treino['duracaoMinutos'] as num?)?.toInt() ?? 30,
          pontosTotais: (treino['pontosTotais'] as num?)?.toInt() ?? 100,
          exercicios: exercicios,
        );

        final novoId =
            res['treino']?['id']?.toString() ?? res['id']?.toString();

        if (mounted) {
          setState(() {
            treino['salvando'] = false;
            treino['salvo'] = true;
            if (novoId != null) {
              treino['idSalvo'] = novoId;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino salvo nos Meus Treinos com sucesso!'),
              backgroundColor: Color(0xFF00E676),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => treino['salvando'] = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar treino: $e'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _carregarTreinos,
          ),
          if (widget.dificuldadeFlag == 'meus_treinos')
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF00E676)),
              tooltip: 'Criar Treino',
              onPressed: () async {
                final criado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CriarExercicioScreen(),
                  ),
                );
                if (criado == true) {
                  _carregarTreinos();
                }
              },
            ),
        ],
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
            child: _carregando
                ? Center(child: CircularProgressIndicator(color: _corTema))
                : _listaTreinos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.fitness_center_outlined,
                          size: 48,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Você ainda não possui treinos salvos.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            final criado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CriarExercicioScreen(),
                              ),
                            );
                            if (criado == true) {
                              _carregarTreinos();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Criar Meu Primeiro Treino'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _carregarTreinos,
                    color: _corTema,
                    backgroundColor: const Color(0xFF1E232A),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _listaTreinos.length,
                      itemBuilder: (context, index) {
                        final treino = _listaTreinos[index];
                        final Color corCard = treino['corTema'] ?? _corTema;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TreinoSelecionadoScreen(
                                    treinoData: treino,
                                  ),
                                ),
                              );
                              _carregarTreinos();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E232A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: corCard.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
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
                                          treino['titulo'] ?? 'Treino',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: treino['salvo'] == true
                                            ? 'Remover dos Meus Treinos'
                                            : 'Salvar nos Meus Treinos',
                                        onPressed: treino['salvando'] == true
                                            ? null
                                            : () => _aoClicarEstrela(treino),
                                        icon: treino['salvando'] == true
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.amber,
                                                    ),
                                              )
                                            : Icon(
                                                treino['salvo'] == true
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: treino['salvo'] == true
                                                    ? Colors.amber
                                                    : Colors.grey,
                                                size: 26,
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${treino['exerciciosCount'] ?? 0} exercícios, ${treino['duracaoMinutos'] ?? 30} minutos',
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
                                      Flexible(
                                        child: Text(
                                          '+${treino['pontosTotais'] ?? 100} pts',
                                          style: TextStyle(
                                            color: corCard,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          treino['dificuldade'] ?? 'Geral',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
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
          ),
        ],
      ),
    );
  }
}
