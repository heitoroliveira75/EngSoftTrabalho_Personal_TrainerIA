import 'camera_treino_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TreinoSelecionadoScreen extends StatefulWidget {
  final Map<String, dynamic> treinoData;

  const TreinoSelecionadoScreen({super.key, required this.treinoData});

  @override
  State<TreinoSelecionadoScreen> createState() =>
      _TreinoSelecionadoScreenState();
}

class _TreinoSelecionadoScreenState extends State<TreinoSelecionadoScreen> {
  bool _salvo = false;
  bool _salvando = false;
  bool _treinando = false;
  int _indiceExercicioAtual = 0;
  List<bool> _exerciciosConcluidos = [];

  @override
  void initState() {
    super.initState();
    _salvo = widget.treinoData['salvo'] == true;
    final exercicios = _obterListaExercicios();
    _exerciciosConcluidos = List.filled(exercicios.length, false);
  }

  List<dynamic> _obterListaExercicios() {
    List exercicios = widget.treinoData['exercicios'] ?? [];
    if (exercicios.isEmpty && widget.treinoData['descricao'] != null) {
      final descStr = widget.treinoData['descricao'].toString().trim();
      if (descStr.startsWith('{') && descStr.endsWith('}')) {
        try {
          final decoded = jsonDecode(descStr);
          if (decoded is Map && decoded['exercicios'] is List) {
            exercicios = decoded['exercicios'];
          }
        } catch (_) {}
      }
    }
    return exercicios;
  }

  String _mapearIdExercicio(String? rawId, String exNome) {
    final nomeLower = exNome.toLowerCase();
    if (rawId == '11' ||
        rawId == '2' ||
        nomeLower.contains('agacha') ||
        nomeLower.contains('squat') ||
        nomeLower.contains('perna')) {
      return '11';
    } else if (rawId == '20' ||
        rawId == '3' ||
        nomeLower.contains('rosca') ||
        nomeLower.contains('biceps') ||
        nomeLower.contains('bíceps') ||
        nomeLower.contains('braço') ||
        nomeLower.contains('braco')) {
      return '20';
    } else {
      return '16';
    }
  }

  void _iniciarTreinoComCamera([int? indice]) {
    final exercicios = _obterListaExercicios();
    if (exercicios.isEmpty) return;

    if (_exerciciosConcluidos.length != exercicios.length) {
      _exerciciosConcluidos = List.filled(exercicios.length, false);
    }

    final targetIndex =
        (indice != null && indice >= 0 && indice < exercicios.length)
            ? indice
            : _indiceExercicioAtual;

    if (targetIndex >= exercicios.length) {
      _executarTreino();
      return;
    }

    final exAtual = exercicios[targetIndex];
    final String exNome = exAtual['nome']?.toString() ?? 'Exercício';
    final int metaReps = (exAtual['repeticoes'] as num?)?.toInt() ?? 10;
    final String rawId =
        (exAtual['exercicio_id'] ?? exAtual['id'])?.toString() ?? '16';
    final String exId = _mapearIdExercicio(rawId, exNome);

    final bool temProximo = (targetIndex + 1) < exercicios.length;
    final String? proximoNome =
        temProximo ? exercicios[targetIndex + 1]['nome']?.toString() : null;

    final exerciciosMapeados = exercicios.map((e) {
      final mapE = Map<String, dynamic>.from(e as Map);
      final rawId = (mapE['exercicio_id'] ?? mapE['id'])?.toString();
      final nomeEx = mapE['nome']?.toString() ?? 'Exercício';
      mapE['exercicio_id'] = _mapearIdExercicio(rawId, nomeEx);
      return mapE;
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraTreinoScreen(
          exercicioId: exId,
          exercicioNome: exNome,
          metaRepeticoes: metaReps,
          exercicioIndice: targetIndex + 1,
          totalExercicios: exercicios.length,
          proximoExercicioNome: proximoNome,
          listaExercicios: exerciciosMapeados,
          indiceInicial: targetIndex,
        ),
      ),
    ).then((resultado) {
      if (!mounted || resultado == null) return;

      bool concluido = false;
      bool treinoConcluido = false;
      List<int> indicesConcluidos = [];

      if (resultado is bool) {
        concluido = resultado;
      } else if (resultado is Map) {
        concluido = resultado['concluido'] == true;
        treinoConcluido = resultado['treinoConcluido'] == true;
        if (resultado['indicesConcluidos'] is List) {
          indicesConcluidos = (resultado['indicesConcluidos'] as List)
              .map((i) => (i as num).toInt())
              .toList();
        }
      }

      if (concluido) {
        setState(() {
          if (indicesConcluidos.isNotEmpty) {
            for (final idx in indicesConcluidos) {
              if (idx >= 0 && idx < _exerciciosConcluidos.length) {
                _exerciciosConcluidos[idx] = true;
              }
            }
            final nextIdx = indicesConcluidos.last + 1;
            if (nextIdx < exercicios.length) {
              _indiceExercicioAtual = nextIdx;
            }
          } else {
            if (targetIndex < _exerciciosConcluidos.length) {
              _exerciciosConcluidos[targetIndex] = true;
            }
            if (targetIndex + 1 < exercicios.length) {
              _indiceExercicioAtual = targetIndex + 1;
            }
          }
        });

        if (treinoConcluido || !_exerciciosConcluidos.contains(false)) {
          // Finaliza o treino completo e consolida pontos totais
          _executarTreino();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exercício "$exNome" concluído com sucesso!'),
              backgroundColor: const Color(0xFF00E676),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _alternarSalvarTreino() async {
    final novoStatus = !_salvo;
    setState(() {
      _salvo = novoStatus;
      widget.treinoData['salvo'] = novoStatus;
    });

    if (novoStatus) {
      setState(() => _salvando = true);
      final idUsuario = ApiService().idUsuarioAtual;
      final exercicios = (widget.treinoData['exercicios'] as List? ?? [])
          .map((e) => {
                'exercicio_id': e['exercicio_id'] ?? e['id'] ?? 1,
                'nome': e['nome'] ?? 'Exercício',
                'series': e['series'] ?? 3,
                'repeticoes': e['repeticoes'] ?? 10,
                'pontos': e['pontos'] ?? e['pontos_totais'] ?? 20,
                'pontos_totais': e['pontos_totais'] ?? e['pontos'] ?? 20,
              })
          .toList();

      try {
        final res = await ApiService().criarTreino(
          usuarioId: idUsuario,
          nome: widget.treinoData['titulo'] ?? 'Treino',
          descricao:
              'Treino salvo dos treinos ${widget.treinoData['dificuldade'] ?? 'padrões'}',
          dificuldade:
              widget.treinoData['dificuldade']?.toString() ?? 'Personalizado',
          duracaoMinutos:
              (widget.treinoData['duracaoMinutos'] as num?)?.toInt() ?? 30,
          pontosTotais:
              (widget.treinoData['pontosTotais'] as num?)?.toInt() ?? 100,
          exercicios: exercicios,
        );

        final novoId = res['treino']?['id']?.toString() ?? res['id']?.toString();
        if (novoId != null && novoId.isNotEmpty) {
          widget.treinoData['idSalvo'] = novoId;
        }

        if (mounted) {
          if (res['sucesso'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Treino salvo nos Meus Treinos com sucesso!'),
                backgroundColor: Color(0xFF00E676),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['mensagem'] ?? 'Treino salvo localmente.'),
                backgroundColor: Colors.blueGrey,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino salvo localmente nos Meus Treinos.'),
              backgroundColor: Colors.blueGrey,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _salvando = false);
      }
    } else {
      setState(() => _salvando = true);
      try {
        String? idParaExcluir = widget.treinoData['idSalvo']?.toString();

        // Se ainda não tínhamos o idSalvo em memória, busca pelo título nos treinos do usuário
        if (idParaExcluir == null || idParaExcluir.isEmpty) {
          final idUsuario = ApiService().idUsuarioAtual;
          final resLista = await ApiService().listarTreinosUsuario(idUsuario);
          final tituloAlvo = (widget.treinoData['titulo'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          if (resLista['sucesso'] == true && resLista['treinos'] is List) {
            for (final t in (resLista['treinos'] as List)) {
              if (t is Map) {
                final nome = (t['nome'] ?? t['titulo'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();
                if (nome == tituloAlvo && t['id'] != null) {
                  idParaExcluir = t['id'].toString();
                  break;
                }
              }
            }
          }
        }

        if (idParaExcluir != null && idParaExcluir.isNotEmpty) {
          await ApiService().excluirTreino(idParaExcluir);
          widget.treinoData['idSalvo'] = null;
        }
      } catch (_) {
      } finally {
        if (mounted) {
          setState(() => _salvando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino removido dos salvos.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _executarTreino() async {
    setState(() => _treinando = true);
    final pontos =
        (widget.treinoData['pontosTotais'] as num?)?.toInt() ?? 100;
    final usuarioId = ApiService().idUsuarioAtual;

    if (usuarioId != null && usuarioId.isNotEmpty) {
      try {
        await ApiService().adicionarPontuacaoDiaria(
          usuarioId: usuarioId,
          pontos: pontos,
        );
      } catch (e) {
        debugPrint('Erro ao sincronizar pontuação no backend: $e');
      }
    }

    if (!mounted) return;
    setState(() => _treinando = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text(
              'Treino Concluído!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parabéns por completar "${widget.treinoData['titulo']}"!',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E676), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pontos Conquistados:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '+$pontos pts',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sua sequência diária foi mantida com sucesso.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx); // fecha dialog
              Navigator.pop(context, true); // volta tela retornando true
            },
            child: const Text(
              'Continuar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color corTema =
        widget.treinoData['corTema'] ?? const Color(0xFF00E676);
    final exercicios = _obterListaExercicios();
    final bool todosConcluidos =
        _exerciciosConcluidos.isNotEmpty && !_exerciciosConcluidos.contains(false);

    String labelBotaoCamera = 'TREINAR COM CÂMERA IA';
    if (todosConcluidos) {
      labelBotaoCamera = 'TREINO CONCLUÍDO (FINALIZAR)';
    } else if (_indiceExercicioAtual > 0 &&
        _indiceExercicioAtual < exercicios.length) {
      final prox = exercicios[_indiceExercicioAtual];
      final String nomeP = prox['nome'] ?? 'PRÓXIMO';
      labelBotaoCamera = 'CONTINUAR: $nomeP';
    }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.treinoData['titulo'] ?? 'Treino',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.treinoData['dificuldade'] ?? 'Geral',
                style: TextStyle(
                  color: corTema,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.treinoData['exerciciosCount'] ?? exercicios.length} exercícios, ${widget.treinoData['duracaoMinutos'] ?? 30} minutos',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 16),

              const Text(
                'Exercícios',
                style: TextStyle(
                  color: Color(0xFF9E7AFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercicios.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ex = exercicios[index];
                  final nomeEx = ex['nome'] ?? 'Exercício';
                  final series = ex['series'] ?? 3;
                  final reps = ex['repeticoes'] ?? 10;
                  final pts = ex['pontos'] ??
                      ex['pontos_totais'] ??
                      (series * 10);
                  final estaConcluido = index < _exerciciosConcluidos.length &&
                      _exerciciosConcluidos[index];
                  final ehOAtual =
                      index == _indiceExercicioAtual && !estaConcluido;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _iniciarTreinoComCamera(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: ehOAtual
                            ? const Color(0xFF1F242C)
                            : (estaConcluido
                                ? const Color(0xFF12161C)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ehOAtual
                              ? corTema.withValues(alpha: 0.6)
                              : (estaConcluido
                                  ? const Color(0xFF00E676)
                                      .withValues(alpha: 0.3)
                                  : Colors.white10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: estaConcluido
                                  ? const Color(0xFF00E676)
                                  : (ehOAtual
                                      ? corTema.withValues(alpha: 0.2)
                                      : Colors.white12),
                            ),
                            child: Center(
                              child: estaConcluido
                                  ? const Icon(Icons.check,
                                      color: Colors.black, size: 18)
                                  : (ehOAtual
                                      ? Icon(Icons.play_arrow,
                                          color: corTema, size: 18)
                                      : Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nomeEx,
                                  style: TextStyle(
                                    color: estaConcluido
                                        ? Colors.white54
                                        : (ehOAtual
                                            ? const Color(0xFF29B6F6)
                                            : Colors.white),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    decoration: estaConcluido
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$series séries × $reps',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '+$pts pts',
                                style: TextStyle(
                                  color: estaConcluido
                                      ? const Color(0xFF00E676)
                                      : corTema,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                estaConcluido
                                    ? Icons.check_circle_outline
                                    : Icons.videocam_outlined,
                                size: 18,
                                color: estaConcluido
                                    ? const Color(0xFF00E676)
                                    : (ehOAtual ? corTema : Colors.white38),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              InkWell(
                onTap: _salvando ? null : _alternarSalvarTreino,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_salvando)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.amber,
                          ),
                        )
                      else
                        Icon(
                          _salvo ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 26,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _salvo
                            ? 'Salvo nos meus Treinos'
                            : 'Salvar nos meus Treinos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: todosConcluidos
                      ? _executarTreino
                      : () => _iniciarTreinoComCamera(_indiceExercicioAtual),
                  icon: Icon(
                    todosConcluidos
                        ? Icons.emoji_events
                        : Icons.videocam_rounded,
                    size: 24,
                  ),
                  label: Text(
                    labelBotaoCamera,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: corTema, width: 2),
                    ),
                  ),
                  onPressed: _treinando ? null : _executarTreino,
                  child: _treinando
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: corTema,
                          ),
                        )
                      : Text(
                          'TREINAR',
                          style: TextStyle(
                            color: corTema,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
