import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/sessao_dupla.dart';
import 'camera_treino_screen.dart';

class LobbyDuplaScreen extends StatefulWidget {
  final String sessaoId;
  final bool isHost;
  final String amigoNome;
  final String amigoId;

  const LobbyDuplaScreen({
    super.key,
    required this.sessaoId,
    required this.isHost,
    required this.amigoNome,
    required this.amigoId,
  });

  @override
  State<LobbyDuplaScreen> createState() => _LobbyDuplaScreenState();
}

class _LobbyDuplaScreenState extends State<LobbyDuplaScreen> {
  Timer? _pollingTimer;
  SessaoDupla? _sessao;
  bool _carregando = true;
  String? _erroMensagem;

  // Treinos disponíveis para a Sessão (carregados do usuário Host)
  List<Map<String, dynamic>> _catalogoTreinos = [];
  String? _treinoSelecionadoId;
  bool _carregandoTreinosHost = false;
  bool _salvandoTreino = false;
  bool _iniciando = false;
  bool _isMesmoAparelho = false;

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

  Map<String, dynamic>? get _treinoSelecionado {
    if (_catalogoTreinos.isEmpty) return null;
    return _catalogoTreinos.firstWhere(
      (t) => t['id']?.toString() == _treinoSelecionadoId,
      orElse: () => _catalogoTreinos.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _carregarEstado();
    if (widget.isHost) {
      _carregarTreinosDoHost();
    }
    // Polling a cada 1.5s para sincronizar status da dupla em tempo real
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _carregarEstado(silencioso: true);
    });
  }

  /// Busca no banco de dados Supabase os treinos criados pelo usuário Host
  Future<void> _carregarTreinosDoHost() async {
    if (!widget.isHost) return;

    setState(() => _carregandoTreinosHost = true);

    try {
      final idHost = ApiService().idUsuarioAtual;
      final res = await ApiService().listarTreinosUsuario(idHost);

      final List<Map<String, dynamic>> treinosEncontrados = [];

      if (res['sucesso'] == true && res['treinos'] is List && (res['treinos'] as List).isNotEmpty) {
        for (final t in (res['treinos'] as List)) {
          if (t is! Map) continue;
          final List<Map<String, dynamic>> exerciciosMapeados = [];

          // 1. Tenta extrair diretamente de t['exercicios']
          if (t['exercicios'] is List && (t['exercicios'] as List).isNotEmpty) {
            for (final ex in t['exercicios']) {
              if (ex is Map) {
                final nomeEx = ex['nome']?.toString() ?? 'Exercício';
                final rawId = (ex['id'] ?? ex['exercicio_id'])?.toString();
                final idIA = _mapearIdExercicio(rawId, nomeEx);
                final series = (ex['series'] as num?)?.toInt() ?? 3;
                final reps = (ex['repeticoes'] as num?)?.toInt() ?? 10;
                exerciciosMapeados.add({
                  'id': idIA,
                  'exercicio_id': idIA,
                  'nome': nomeEx,
                  'grupo_muscular': ex['grupo_muscular'] ?? 'Geral',
                  'series': series,
                  'repeticoes': reps,
                });
              }
            }
          }
          // 2. Tenta extrair da relação relacional t['treino_exercicios']
          else if (t['treino_exercicios'] is List && (t['treino_exercicios'] as List).isNotEmpty) {
            for (final te in (t['treino_exercicios'] as List)) {
              if (te is Map) {
                final exInfo = te['exercicios'] as Map<String, dynamic>? ?? {};
                final nomeEx = exInfo['nome'] ?? te['nome'] ?? 'Exercício';
                final rawId = (te['exercicio_id'] ?? te['id'])?.toString();
                final idIA = _mapearIdExercicio(rawId, nomeEx.toString());
                final series = (te['series'] as num?)?.toInt() ?? 3;
                final reps = (te['repeticoes'] as num?)?.toInt() ?? 10;
                exerciciosMapeados.add({
                  'id': idIA,
                  'exercicio_id': idIA,
                  'nome': nomeEx.toString(),
                  'grupo_muscular': exInfo['grupo_muscular'] ?? 'Geral',
                  'series': series,
                  'repeticoes': reps,
                });
              }
            }
          }
          // 3. Fallback: tenta desempacotar JSON em t['descricao']
          else if (t['descricao'] != null && t['descricao'].toString().trim().startsWith('{')) {
            try {
              final Map<String, dynamic> parsed = jsonDecode(t['descricao'].toString());
              if (parsed['exercicios'] is List) {
                for (final ex in (parsed['exercicios'] as List)) {
                  if (ex is Map) {
                    final nomeEx = ex['nome']?.toString() ?? 'Exercício';
                    final rawId = (ex['id'] ?? ex['exercicio_id'])?.toString();
                    final idIA = _mapearIdExercicio(rawId, nomeEx);
                    final series = (ex['series'] as num?)?.toInt() ?? 3;
                    final reps = (ex['repeticoes'] as num?)?.toInt() ?? 10;
                    exerciciosMapeados.add({
                      'id': idIA,
                      'exercicio_id': idIA,
                      'nome': nomeEx,
                      'grupo_muscular': ex['grupo_muscular'] ?? 'Geral',
                      'series': series,
                      'repeticoes': reps,
                    });
                  }
                }
              }
            } catch (_) {}
          }

          treinosEncontrados.add({
            'id': t['id']?.toString() ?? 'custom',
            'titulo': t['nome'] ?? t['titulo'] ?? 'Treino Customizado',
            'dificuldade': t['dificuldade'] ?? 'Personalizado',
            'descricao': t['descricao_texto'] ?? 'Treino criado pelo usuário host',
            'exercicios': exerciciosMapeados.isNotEmpty
                ? exerciciosMapeados
                : [
                    {
                      'id': '16',
                      'exercicio_id': '16',
                      'nome': 'Desenvolvimento com Halteres',
                      'grupo_muscular': 'Ombro',
                      'series': 3,
                      'repeticoes': 10,
                    }
                  ],
          });
        }
      }

      if (mounted) {
        setState(() {
          _carregandoTreinosHost = false;
          _catalogoTreinos = treinosEncontrados;
          if (_catalogoTreinos.isNotEmpty) {
            if (_treinoSelecionadoId == null ||
                !_catalogoTreinos.any((t) => t['id']?.toString() == _treinoSelecionadoId)) {
              _treinoSelecionadoId = _catalogoTreinos.first['id'].toString();
            }
          } else {
            _treinoSelecionadoId = null;
          }
        });

        if (_catalogoTreinos.isNotEmpty) {
          _salvarConfiguracaoTreino();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregandoTreinosHost = false);
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarEstado({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() => _carregando = true);
    }
    try {
      final res = await ApiService().obterEstadoSessaoDupla(widget.sessaoId);
      if (!mounted) return;

      if (res['sucesso'] == true && res['sessao'] != null) {
        final sessao = SessaoDupla.fromJson(Map<String, dynamic>.from(res['sessao'] as Map));
        setState(() {
          _sessao = sessao;
          _carregando = false;
          _erroMensagem = null;
        });

        // Se o amigo recusou ou cancelou
        if (sessao.isRecusado) {
          _pollingTimer?.cancel();
          _mostrarAviso('O amigo recusou o convite para treinar em dupla.', pop: true);
        } else if (sessao.isCancelado) {
          _pollingTimer?.cancel();
          _mostrarAviso('A sessão foi cancelada.', pop: true);
        } else if (sessao.isEmAndamento && !_iniciando) {
          // O treino iniciou! Redireciona ambos para a câmera
          _pollingTimer?.cancel();
          _iniciarTelaTreino(sessao);
        }
      } else {
        if (!silencioso) {
          setState(() {
            _carregando = false;
            _erroMensagem = res['mensagem'] ?? 'Erro ao carregar sessão.';
          });
        }
      }
    } catch (e) {
      if (!silencioso && mounted) {
        setState(() {
          _carregando = false;
          _erroMensagem = 'Erro de conexão: $e';
        });
      }
    }
  }

  void _mostrarAviso(String msg, {bool pop = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.amber[800],
      ),
    );
    if (pop) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _salvarConfiguracaoTreino() async {
    final treino = _treinoSelecionado;
    if (treino == null) return;

    setState(() => _salvandoTreino = true);
    try {
      final rawExercicios = (treino['exercicios'] as List? ?? []);

      final List<Map<String, dynamic>> exerciciosFormatados = rawExercicios.map((e) {
        final mapE = Map<String, dynamic>.from(e as Map);
        final nome = mapE['nome']?.toString() ?? 'Exercício';
        final rawId = (mapE['exercicio_id'] ?? mapE['id'])?.toString();
        final idIA = _mapearIdExercicio(rawId, nome);
        final series = (mapE['series'] as num?)?.toInt() ?? 3;
        final reps = (mapE['repeticoes'] as num?)?.toInt() ?? 10;

        return {
          'id': idIA,
          'exercicio_id': idIA,
          'nome': nome,
          'grupo_muscular': mapE['grupo_muscular'] ?? 'Geral',
          'series': series,
          'repeticoes': reps,
        };
      }).toList();

      final dadosTreino = {
        'nome': treino['titulo'] ?? treino['nome'] ?? 'Treino em Dupla',
        'treino_id': treino['id'],
        'dificuldade': treino['dificuldade'] ?? 'Intermediário',
        'exercicios': exerciciosFormatados,
      };

      final totalSeriesTreino = exerciciosFormatados.isNotEmpty
          ? (exerciciosFormatados.first['series'] as int)
          : 3;

      final res = await ApiService().selecionarTreinoDupla(
        sessaoId: widget.sessaoId,
        treinoId: treino['id']?.toString(),
        dadosTreino: dadosTreino,
        totalSeries: totalSeriesTreino,
      );

      if (mounted) {
        setState(() => _salvandoTreino = false);
        if (res['sucesso'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Treino "${dadosTreino['nome']}" sincronizado com o parceiro!'),
              backgroundColor: const Color(0xFF00E676),
            ),
          );
          _carregarEstado(silencioso: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvandoTreino = false);
      }
    }
  }

  Future<void> _darPartidaNoTreino() async {
    if (_sessao == null) return;
    if (!_isMesmoAparelho && _sessao!.isPendente) {
      _mostrarAviso('Aguarde o parceiro aceitar o convite para iniciar!');
      return;
    }
    if (widget.isHost && (_catalogoTreinos.isEmpty || _treinoSelecionado == null)) {
      _mostrarAviso('Crie ou selecione um treino antes de iniciar!');
      return;
    }

    setState(() => _iniciando = true);
    try {
      // Salva a configuração atual antes de iniciar
      await _salvarConfiguracaoTreino();

      final res = await ApiService().iniciarTreinoDupla(sessaoId: widget.sessaoId);
      if (mounted) {
        if (res['sucesso'] == true) {
          final sessaoAtualizada = SessaoDupla.fromJson(
            Map<String, dynamic>.from(res['sessao'] as Map),
          );
          _pollingTimer?.cancel();
          _iniciarTelaTreino(sessaoAtualizada);
        } else {
          setState(() => _iniciando = false);
          _mostrarAviso(res['mensagem'] ?? 'Erro ao iniciar treino.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _iniciando = false);
        _mostrarAviso('Erro ao iniciar treino: $e');
      }
    }
  }

  void _iniciarTelaTreino(SessaoDupla sessao) {
    List<Map<String, dynamic>> listaEx = [];
    if (sessao.dadosTreino['exercicios'] is List &&
        (sessao.dadosTreino['exercicios'] as List).isNotEmpty) {
      listaEx = List<Map<String, dynamic>>.from(
        (sessao.dadosTreino['exercicios'] as List).map((e) {
          final mapE = Map<String, dynamic>.from(e as Map);
          final nome = mapE['nome']?.toString() ?? 'Exercício';
          final rawId = (mapE['exercicio_id'] ?? mapE['id'])?.toString();
          mapE['exercicio_id'] = _mapearIdExercicio(rawId, nome);
          mapE['id'] = mapE['exercicio_id'];
          return mapE;
        }),
      );
    } else {
      listaEx = [
        {
          'id': '16',
          'exercicio_id': '16',
          'nome': 'Desenvolvimento com Halteres',
          'series': 3,
          'repeticoes': 10,
        }
      ];
    }

    final exAtual = listaEx.first;
    final int seriesEx = (exAtual['series'] as num?)?.toInt() ?? sessao.totalSeries;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CameraTreinoScreen(
          exercicioId: exAtual['id']?.toString() ?? '16',
          exercicioNome: exAtual['nome']?.toString() ?? 'Desenvolvimento com Halteres',
          metaRepeticoes: (exAtual['repeticoes'] as num?)?.toInt() ?? 10,
          totalSeries: seriesEx,
          listaExercicios: listaEx,
          isModoDupla: true,
          isMesmoAparelho: _isMesmoAparelho,
          sessaoDuplaId: widget.sessaoId,
          parceiroId: widget.amigoId,
          parceiroNome: widget.amigoNome,
          isHostDupla: widget.isHost,
        ),
      ),
    );
  }

  Future<void> _cancelarOuSair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232A),
        title: const Text('Sair do Lobby?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Deseja cancelar o treino em dupla e voltar para a lista de amigos?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _pollingTimer?.cancel();
      await ApiService().responderConviteTreino(
        sessaoId: widget.sessaoId,
        resposta: 'cancelado',
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _sessao?.status ?? 'pendente';
    final bool parceiroPronto = status == 'aceito';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancelarOuSair,
        ),
        title: const Text(
          'LOBBY DE TREINO EM DUPLA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontSize: 16,
          ),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_erroMensagem != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _erroMensagem!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // Banner de Gamificação Cooperativa (+20% Bônus)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E676).withValues(alpha: 0.2),
                          const Color(0xFF8A5CF5).withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 26)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BÔNUS COOPERATIVO DE +20%',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Treinem em revezamento por série. Ao final, ambos recebem 1.2x a pontuação média da dupla!',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card de Participantes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E232A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PARTICIPANTES',
                          style: TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Host
                        _buildAtletaLinha(
                          nome: widget.isHost
                              ? '${ApiService().nomeUsuarioAtual} (Você)'
                              : widget.amigoNome,
                          papel: 'Host da Sessão',
                          isOnline: true,
                          isHost: true,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Colors.white10),
                        ),

                        // Convidado
                        _buildAtletaLinha(
                          nome: widget.isHost
                              ? widget.amigoNome
                              : '${ApiService().nomeUsuarioAtual} (Você)',
                          papel: 'Parceiro Convidado',
                          isOnline: _isMesmoAparelho || parceiroPronto,
                          isHost: false,
                          statusTexto: _isMesmoAparelho
                              ? 'Presente (Mesmo Celular)'
                              : (parceiroPronto ? 'No Lobby (Pronto)' : 'Aguardando confirmação...'),
                        ),
                      ],
                    ),
                  ),

                  // Seletor de Formato: Mesmo Celular vs Celulares Separados
                  if (widget.isHost) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E232A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FORMATO DA SESSÃO',
                            style: TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Opção 1: Mesmo Celular (Presencial)
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _isMesmoAparelho = true),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _isMesmoAparelho
                                          ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                          : const Color(0xFF0D1117),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _isMesmoAparelho
                                            ? const Color(0xFF00E676)
                                            : Colors.white12,
                                        width: _isMesmoAparelho ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.phone_android,
                                          color: _isMesmoAparelho ? const Color(0xFF00E676) : Colors.white60,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '1 Celular (Juntos)',
                                          style: TextStyle(
                                            color: _isMesmoAparelho ? Colors.white : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Revezem a mesma câmera',
                                          style: TextStyle(
                                            color: _isMesmoAparelho ? const Color(0xFF00E676) : Colors.white38,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Opção 2: Celulares Separados (Remoto)
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _isMesmoAparelho = false),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: !_isMesmoAparelho
                                          ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                          : const Color(0xFF0D1117),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: !_isMesmoAparelho
                                            ? const Color(0xFF00E676)
                                            : Colors.white12,
                                        width: !_isMesmoAparelho ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.devices,
                                          color: !_isMesmoAparelho ? const Color(0xFF00E676) : Colors.white60,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '2 Celulares (Online)',
                                          style: TextStyle(
                                            color: !_isMesmoAparelho ? Colors.white : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cada um no seu aparelho',
                                          style: TextStyle(
                                            color: !_isMesmoAparelho ? const Color(0xFF00E676) : Colors.white38,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Configuração de Treino Completo (US-DUPLA)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E232A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TREINO COMPLETO DA DUPLA',
                              style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.1,
                              ),
                            ),
                            if (!widget.isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Definido pelo Host',
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (widget.isHost) ...[
                          if (_carregandoTreinosHost)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(color: Color(0xFF00E676)),
                              ),
                            )
                          else if (_catalogoTreinos.isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1117),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.fitness_center_outlined, color: Colors.amberAccent, size: 30),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Você não possui treinos criados no seu perfil.',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Crie rotinas em "Meus Treinos" para selecioná-las aqui na sessão em dupla.',
                                    style: TextStyle(color: Colors.white60, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _carregarTreinosDoHost,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Recarregar Meus Treinos'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF00E676),
                                      side: const BorderSide(color: Color(0xFF00E676)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Seletor de Treino do Host com botão de Recarregar
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _treinoSelecionadoId,
                                    dropdownColor: const Color(0xFF1E232A),
                                    decoration: InputDecoration(
                                      labelText: 'Seus Treinos Cadastrados',
                                      labelStyle: const TextStyle(color: Colors.white70),
                                      filled: true,
                                      fillColor: const Color(0xFF0D1117),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Colors.white24),
                                      ),
                                    ),
                                    items: _catalogoTreinos.map((t) {
                                      final totalEx = (t['exercicios'] as List? ?? []).length;
                                      return DropdownMenuItem<String>(
                                        value: t['id'].toString(),
                                        child: Text(
                                          '${t['titulo']} ($totalEx ex)',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _treinoSelecionadoId = val);
                                        _salvarConfiguracaoTreino();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.refresh, color: Color(0xFF00E676)),
                                  tooltip: 'Recarregar meus treinos',
                                  onPressed: _carregarTreinosDoHost,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Card de Detalhes dos Exercícios do Treino Escolhido
                            if (_treinoSelecionado != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1117),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${_treinoSelecionado!['titulo']}',
                                            style: const TextStyle(
                                              color: Color(0xFF00E676),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _treinoSelecionado!['dificuldade'] ?? 'Personalizado',
                                            style: const TextStyle(
                                              color: Color(0xFF00E676),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...((_treinoSelecionado!['exercicios'] as List? ?? []).asMap().entries.map((entry) {
                                      final idx = entry.key + 1;
                                      final ex = entry.value as Map<String, dynamic>;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 10,
                                              backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.2),
                                              child: Text(
                                                '$idx',
                                                style: const TextStyle(
                                                  color: Color(0xFF00E676),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                ex['nome']?.toString() ?? 'Exercício',
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                              ),
                                            ),
                                            Text(
                                              '${ex['series'] ?? 3}x ${ex['repeticoes'] ?? 10} reps',
                                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      );
                                    })),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _salvandoTreino ? null : _salvarConfiguracaoTreino,
                              icon: _salvandoTreino
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676)),
                                    )
                                  : const Icon(Icons.sync, size: 18),
                              label: const Text('Sincronizar Treino com Convidado'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00E676),
                                side: const BorderSide(color: Color(0xFF00E676)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ] else ...[
                          // Visualização do Convidado
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _sessao?.dadosTreino['nome']?.toString() ?? 'Circuito Completo',
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _sessao?.dadosTreino['dificuldade']?.toString() ?? 'Em Dupla',
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_sessao?.dadosTreino['exercicios'] is List)
                                  ...((_sessao!.dadosTreino['exercicios'] as List).asMap().entries.map((entry) {
                                    final idx = entry.key + 1;
                                    final ex = Map<String, dynamic>.from(entry.value as Map);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 10,
                                            backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.2),
                                            child: Text(
                                              '$idx',
                                              style: const TextStyle(
                                                color: Color(0xFF00E676),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              ex['nome']?.toString() ?? 'Exercício',
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                            ),
                                          ),
                                          Text(
                                            '${ex['series'] ?? 3}x ${ex['repeticoes'] ?? 10} reps',
                                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  }))
                                else
                                  Text(
                                    '${_sessao?.totalSeries ?? 3} séries por exercício em revezamento',
                                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botão de Ação Principal
                  if (widget.isHost)
                    ElevatedButton.icon(
                      onPressed: (_iniciando || !parceiroPronto || _catalogoTreinos.isEmpty || _treinoSelecionado == null)
                          ? null
                          : _darPartidaNoTreino,
                      icon: _iniciando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 24),
                      label: Text(
                        _catalogoTreinos.isEmpty
                            ? 'CRIE UM TREINO PARA INICIAR'
                            : (parceiroPronto
                                ? '🚀 INICIAR TREINO EM DUPLA'
                                : 'AGUARDANDO O PARCEIRO ACEITAR...'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676)),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Aguardando o Host iniciar a sessão...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: _cancelarOuSair,
                    icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                    label: const Text('Cancelar e Sair do Lobby', style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAtletaLinha({
    required String nome,
    required String papel,
    required bool isOnline,
    required bool isHost,
    String? statusTexto,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isHost ? const Color(0xFF8A5CF5) : const Color(0xFF00E676),
          child: Text(
            nome.isNotEmpty ? nome[0].toUpperCase() : 'A',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                statusTexto ?? papel,
                style: TextStyle(
                  color: isOnline ? const Color(0xFF00E676) : Colors.amberAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(
          isOnline ? Icons.check_circle : Icons.hourglass_top_rounded,
          color: isOnline ? const Color(0xFF00E676) : Colors.amberAccent,
          size: 20,
        ),
      ],
    );
  }
}
