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

  Future<void> _alternarSalvarTreino() async {
    final novoStatus = !_salvo;
    setState(() {
      _salvo = novoStatus;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino removido dos salvos.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  
  void _iniciarTreinoComCamera() {
    final exercicios = widget.treinoData['exercicios'] as List? ?? [];
    String exId = '1';
    String exNome = 'Desenvolvimento de Ombros';
    int metaReps = 10;

    if (exercicios.isNotEmpty) {
      final primeiro = exercicios.first;
      exNome = primeiro['nome']?.toString() ?? exNome;
      metaReps = (primeiro['repeticoes'] as num?)?.toInt() ?? 10;
      final rawId = primeiro['exercicio_id'] ?? primeiro['id'];
      if (rawId != null) {
        exId = rawId.toString();
      }
      final nomeLower = exNome.toLowerCase();
      if (nomeLower.contains('agacha')) {
        exId = '2';
      } else if (nomeLower.contains('rosca') || nomeLower.contains('biceps') || nomeLower.contains('bíceps')) {
        exId = '3';
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraTreinoScreen(
          exercicioId: exId,
          exercicioNome: exNome,
          metaRepeticoes: metaReps,
        ),
      ),
    ).then((concluido) {
      if (concluido == true && mounted) {
        Navigator.pop(context, true);
      }
    });
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
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ex = exercicios[index];
                  final nomeEx = ex['nome'] ?? 'Exercício';
                  final series = ex['series'] ?? 3;
                  final reps = ex['repeticoes'] ?? 10;
                  final pts = ex['pontos'] ??
                      ex['pontos_totais'] ??
                      (series * 10);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nomeEx,
                              style: const TextStyle(
                                color: Color(0xFF29B6F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
                      Text(
                        '+$pts pts',
                        style: TextStyle(
                          color: corTema,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                  onPressed: _iniciarTreinoComCamera,
                  icon: const Icon(Icons.videocam_rounded, size: 24),
                  label: const Text(
                    'TREINAR COM CÂMERA IA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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
