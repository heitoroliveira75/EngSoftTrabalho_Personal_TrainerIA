import 'camera_treino_screen.dart';
import 'criar_exercicio_screen.dart';

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
  String? _idSalvo;
  int _indiceExercicioAtual = 0;
  List<bool> _exerciciosConcluidos = [];
  late List<Map<String, dynamic>> _listaExercicios;

  @override
  void initState() {
    super.initState();
    _salvo =
        widget.treinoData['salvo'] == true ||
        widget.treinoData['ehMeusTreinos'] == true;
    _idSalvo =
        widget.treinoData['idSalvo']?.toString() ??
        widget.treinoData['id']?.toString();
    final rawExercicios = _obterListaExercicios();
    _listaExercicios = rawExercicios
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _exerciciosConcluidos = List.filled(_listaExercicios.length, false);
  }

  void _aoReordenarExercicios(int oldIndex, int newIndex) async {
    setState(() {
      final item = _listaExercicios.removeAt(oldIndex);
      _listaExercicios.insert(newIndex, item);

      if (_exerciciosConcluidos.isNotEmpty &&
          _exerciciosConcluidos.length == _listaExercicios.length) {
        final status = _exerciciosConcluidos.removeAt(oldIndex);
        _exerciciosConcluidos.insert(newIndex, status);
      }

      widget.treinoData['exercicios'] = _listaExercicios;
    });

    final idTreino =
        _idSalvo ??
        widget.treinoData['idSalvo']?.toString() ??
        widget.treinoData['id']?.toString();

    // Sincroniza a nova ordem no backend caso o treino esteja persistido no banco
    if (idTreino != null && idTreino.isNotEmpty && _salvo) {
      final exerciciosPayload = _listaExercicios.asMap().entries.map((entry) {
        final idx = entry.key;
        final ex = entry.value;
        final rawId = ex['exercicio_id'] ?? ex['id'] ?? (idx + 1);
        final exId = int.tryParse(rawId.toString()) ?? (idx + 1);
        return {
          'exercicio_id': exId,
          'ordem': idx + 1,
          'series': ex['series'] ?? 3,
          'repeticoes': ex['repeticoes'] ?? 10,
          'nome': ex['nome'] ?? 'Exercício',
          'grupo_muscular': ex['grupo_muscular'] ?? 'Geral',
          'pontos_totais': ex['pontos'] ?? ex['pontos_totais'] ?? 45,
        };
      }).toList();

      try {
        await ApiService().editarTreino(
          idTreino,
          exercicios: exerciciosPayload,
        );
      } catch (e) {
        debugPrint('Erro ao persistir nova ordem do treino no banco: $e');
      }
    }
  }

  Future<void> _abrirEdicaoTreino() async {
    final dadosParaEdicao = {
      ...widget.treinoData,
      'id':
          _idSalvo ??
          widget.treinoData['idSalvo']?.toString() ??
          widget.treinoData['id']?.toString(),
      'idSalvo':
          _idSalvo ??
          widget.treinoData['idSalvo']?.toString() ??
          widget.treinoData['id']?.toString(),
      'exercicios': _listaExercicios
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    };

    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CriarExercicioScreen(treinoParaEditar: dadosParaEdicao),
      ),
    );

    if (!mounted || resultado == null) return;

    setState(() {
      if (resultado['titulo'] != null) {
        widget.treinoData['titulo'] = resultado['titulo'];
      }
      if (resultado['exercicios'] is List) {
        _listaExercicios = (resultado['exercicios'] as List)
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
        widget.treinoData['exercicios'] = _listaExercicios;
        widget.treinoData['exerciciosCount'] = _listaExercicios.length;
      }
      if (resultado['duracaoMinutos'] != null) {
        widget.treinoData['duracaoMinutos'] = resultado['duracaoMinutos'];
      }
      if (resultado['pontosTotais'] != null) {
        widget.treinoData['pontosTotais'] = resultado['pontosTotais'];
      }

      // Reajusta o controle de progresso com segurança para não dar RangeError
      _exerciciosConcluidos = List.filled(_listaExercicios.length, false);
      if (_indiceExercicioAtual >= _listaExercicios.length) {
        _indiceExercicioAtual = 0;
      }
    });
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
    final raw = (rawId ?? '').trim();
    if (raw == '11' ||
        raw == '2' ||
        nomeLower.contains('agacha') ||
        nomeLower.contains('squat') ||
        nomeLower.contains('perna')) {
      return '11';
    } else if (raw == '20' ||
        raw == '3' ||
        nomeLower.contains('rosca') ||
        nomeLower.contains('biceps') ||
        nomeLower.contains('bíceps')) {
      return '20';
    } else if (raw == '17' ||
        raw == '4' ||
        nomeLower.contains('eleva') ||
        nomeLower.contains('lateral')) {
      return '17';
    } else if (raw == '24' ||
        raw == '23' ||
        raw == '5' ||
        nomeLower.contains('triceps') ||
        nomeLower.contains('tríceps') ||
        nomeLower.contains('corda')) {
      return '24';
    } else if (raw == '6' ||
        nomeLower.contains('diamante') ||
        (nomeLower.contains('flex') &&
            !nomeLower.contains('mesa') &&
            !nomeLower.contains('cadeira'))) {
      return '5';
    } else if (raw == '7' || nomeLower.contains('remada')) {
      return '7';
    } else {
      return '16';
    }
  }

  void _iniciarTreinoComCamera([int? indice]) {
    final exercicios = _listaExercicios;
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
    final int seriesEx = (exAtual['series'] as num?)?.toInt() ?? 3;
    final String rawId =
        (exAtual['exercicio_id'] ?? exAtual['id'])?.toString() ?? '16';
    final String exId = _mapearIdExercicio(rawId, exNome);

    final bool temProximo = (targetIndex + 1) < exercicios.length;
    final String? proximoNome = temProximo
        ? exercicios[targetIndex + 1]['nome']?.toString()
        : null;

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
          totalSeries: seriesEx,
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
    if (_salvando) return;

    if (_salvo) {
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
            'Deseja realmente remover o treino "${widget.treinoData['titulo'] ?? 'Treino'}" dos Meus Treinos?\n\nEle deixará de constar na sua lista de treinos.',
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

      setState(() => _salvando = true);

      try {
        final idParaExcluir =
            _idSalvo ??
            widget.treinoData['idSalvo']?.toString() ??
            widget.treinoData['id']?.toString();

        if (idParaExcluir != null && idParaExcluir.isNotEmpty) {
          await ApiService().excluirTreino(idParaExcluir);
        }

        if (mounted) {
          setState(() {
            _salvo = false;
            _idSalvo = null;
            _salvando = false;
            widget.treinoData['salvo'] = false;
            widget.treinoData['idSalvo'] = null;
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
          setState(() => _salvando = false);
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
      setState(() => _salvando = true);
      final idUsuario = ApiService().idUsuarioAtual;
      final exercicios = (widget.treinoData['exercicios'] as List? ?? [])
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

        final novoId =
            res['treino']?['id']?.toString() ?? res['id']?.toString();

        if (mounted) {
          setState(() {
            _salvo = true;
            if (novoId != null) {
              _idSalvo = novoId;
              widget.treinoData['idSalvo'] = novoId;
            }
            widget.treinoData['salvo'] = true;
            _salvando = false;
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
          setState(() => _salvando = false);
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

  Future<void> _executarTreino() async {
    final pontos = (widget.treinoData['pontosTotais'] as num?)?.toInt() ?? 100;
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Treino Concluído!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
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
                  const Flexible(
                    child: Text(
                      'Pontos Conquistados:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
    const Color corTema = Color(0xFF00E676);
    final exercicios = _listaExercicios;
    final bool todosConcluidos =
        _exerciciosConcluidos.isNotEmpty &&
        !_exerciciosConcluidos.contains(false);

    String labelBotaoCamera = 'TREINAR';
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
            color: const Color(0xFF1E232A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.treinoData['titulo'] ?? 'Treino',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_salvo)
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 8),
                      tooltip: 'Editar Treino',
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF29B6F6),
                        size: 26,
                      ),
                      onPressed: _abrirEdicaoTreino,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.treinoData['dificuldade'] ?? 'Geral',
                style: const TextStyle(
                  color: corTema,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.treinoData['exerciciosCount'] ?? exercicios.length} exercícios, ${widget.treinoData['duracaoMinutos'] ?? 30} minutos',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Exercícios',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (exercicios.length > 1) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Arraste pelo ícone ≡ para reordenar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: exercicios.length,
                onReorderItem: _aoReordenarExercicios,
                itemBuilder: (context, index) {
                  final ex = exercicios[index];
                  final nomeEx = ex['nome'] ?? 'Exercício';
                  final series = ex['series'] ?? 3;
                  final reps = ex['repeticoes'] ?? 10;
                  final pts =
                      ex['pontos'] ?? ex['pontos_totais'] ?? (series * 10);
                  final estaConcluido =
                      index < _exerciciosConcluidos.length &&
                      _exerciciosConcluidos[index];
                  final ehOAtual =
                      index == _indiceExercicioAtual && !estaConcluido;

                  return Container(
                    key: ObjectKey(ex),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _iniciarTreinoComCamera(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ehOAtual
                              ? const Color(0xFF2D3139)
                              : (estaConcluido
                                    ? const Color(0xFF161B22)
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
                            // Handle para arrastar e reordenar
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.only(
                                  right: 8,
                                  top: 4,
                                  bottom: 4,
                                ),
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.drag_handle,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                              ),
                            ),
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
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: 18,
                                      )
                                    : (ehOAtual
                                          ? const Icon(
                                              Icons.play_arrow,
                                              color: corTema,
                                              size: 18,
                                            )
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
                                                ? const Color(0xFF00E676)
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
                                    style: const TextStyle(
                                      color: Colors.white60,
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
                                  style: const TextStyle(
                                    color: Color(0xFF00E676),
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
                      Flexible(
                        child: Text(
                          _salvo
                              ? 'Salvo nos meus Treinos'
                              : 'Salvar nos meus Treinos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
            ],
          ),
        ),
      ),
    );
  }
}
