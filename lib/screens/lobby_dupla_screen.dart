import 'dart:async';
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

  // Opções de treinos rápidos pré-configurados
  final List<Map<String, dynamic>> _catalogoExercicios = [
    {
      'id': '16',
      'nome': 'Desenvolvimento com Halteres',
      'grupo_muscular': 'Ombro',
      'series': 3,
      'repeticoes': 10,
    },
    {
      'id': '11',
      'nome': 'Agachamento Livre',
      'grupo_muscular': 'Pernas',
      'series': 3,
      'repeticoes': 10,
    },
    {
      'id': '20',
      'nome': 'Rosca Direta com Barra',
      'grupo_muscular': 'Bíceps',
      'series': 3,
      'repeticoes': 12,
    },
  ];

  late String _exercicioSelecionadoId;
  int _seriesSelecionadas = 3;
  int _repeticoesSelecionadas = 10;
  bool _salvandoTreino = false;
  bool _iniciando = false;

  @override
  void initState() {
    super.initState();
    _exercicioSelecionadoId = _catalogoExercicios.first['id'];
    _carregarEstado();
    // Polling a cada 1.5s para sincronizar status da dupla em tempo real
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _carregarEstado(silencioso: true);
    });
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
    setState(() => _salvandoTreino = true);
    try {
      final exEscolhido = _catalogoExercicios.firstWhere(
        (e) => e['id'] == _exercicioSelecionadoId,
        orElse: () => _catalogoExercicios.first,
      );

      final dadosTreino = {
        'nome': 'Treino Dupla: ${exEscolhido['nome']}',
        'exercicios': [
          {
            'id': exEscolhido['id'],
            'exercicio_id': exEscolhido['id'],
            'nome': exEscolhido['nome'],
            'grupo_muscular': exEscolhido['grupo_muscular'],
            'series': _seriesSelecionadas,
            'repeticoes': _repeticoesSelecionadas,
          }
        ]
      };

      final res = await ApiService().selecionarTreinoDupla(
        sessaoId: widget.sessaoId,
        treinoId: null,
        dadosTreino: dadosTreino,
        totalSeries: _seriesSelecionadas,
      );

      if (mounted) {
        setState(() => _salvandoTreino = false);
        if (res['sucesso'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuração de treino sincronizada com o parceiro!'),
              backgroundColor: Color(0xFF00E676),
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
    if (_sessao!.isPendente) {
      _mostrarAviso('Aguarde o parceiro aceitar o convite para iniciar!');
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
        (sessao.dadosTreino['exercicios'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CameraTreinoScreen(
          exercicioId: exAtual['id']?.toString() ?? '16',
          exercicioNome: exAtual['nome']?.toString() ?? 'Desenvolvimento com Halteres',
          metaRepeticoes: (exAtual['repeticoes'] as num?)?.toInt() ?? 10,
          listaExercicios: listaEx,
          isModoDupla: true,
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
                          isOnline: parceiroPronto,
                          isHost: false,
                          statusTexto: parceiroPronto ? 'No Lobby (Pronto)' : 'Aguardando confirmação...',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Configuração de Treino
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
                              'EXERCÍCIO E CARGA',
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
                          // Seletor de Exercício
                          DropdownButtonFormField<String>(
                            initialValue: _exercicioSelecionadoId,
                            dropdownColor: const Color(0xFF1E232A),
                            decoration: InputDecoration(
                              labelText: 'Exercício Biomecânico',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF0D1117),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                            ),
                            items: _catalogoExercicios.map((ex) {
                              return DropdownMenuItem<String>(
                                value: ex['id'].toString(),
                                child: Text(
                                  ex['nome'].toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _exercicioSelecionadoId = val);
                              }
                            },
                          ),

                          const SizedBox(height: 12),

                          // Séries e Repetições
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _seriesSelecionadas,
                                  dropdownColor: const Color(0xFF1E232A),
                                  decoration: InputDecoration(
                                    labelText: 'Total de Séries',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: const Color(0xFF0D1117),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: [1, 2, 3, 4, 5].map((s) {
                                    return DropdownMenuItem<int>(
                                      value: s,
                                      child: Text('$s séries', style: const TextStyle(color: Colors.white)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _seriesSelecionadas = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _repeticoesSelecionadas,
                                  dropdownColor: const Color(0xFF1E232A),
                                  decoration: InputDecoration(
                                    labelText: 'Reps por Série',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: const Color(0xFF0D1117),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: [6, 8, 10, 12, 15].map((r) {
                                    return DropdownMenuItem<int>(
                                      value: r,
                                      child: Text('$r reps', style: const TextStyle(color: Colors.white)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _repeticoesSelecionadas = val);
                                    }
                                  },
                                ),
                              ),
                            ],
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
                            label: const Text('Sincronizar Exercício com Convidado'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00E676),
                              side: const BorderSide(color: Color(0xFF00E676)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ] else ...[
                          // Visualização do Convidado
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF00E676),
                              child: Icon(Icons.fitness_center, color: Colors.black),
                            ),
                            title: Text(
                              _sessao?.dadosTreino['nome']?.toString() ?? 'Desenvolvimento com Halteres',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${_sessao?.totalSeries ?? 3} séries de revezamento com IA',
                              style: const TextStyle(color: Colors.white60),
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
                      onPressed: (_iniciando || !parceiroPronto) ? null : _darPartidaNoTreino,
                      icon: _iniciando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 24),
                      label: Text(
                        parceiroPronto
                            ? '🚀 INICIAR TREINO EM DUPLA'
                            : 'AGUARDANDO O PARCEIRO ACEITAR...',
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
