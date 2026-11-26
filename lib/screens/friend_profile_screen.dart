import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lobby_dupla_screen.dart';

class FriendProfileScreen extends StatefulWidget {
  final String amigoId;
  final Map<String, dynamic>? dadosIniciais;
  final bool? isAmigoInicial;
  final bool? isAmigoConfirmado;
  final int? posicaoGlobalInicial;
  final int? posicaoAmigosInicial;
  final VoidCallback? onBack;

  const FriendProfileScreen({
    super.key,
    required this.amigoId,
    this.dadosIniciais,
    this.isAmigoInicial,
    this.isAmigoConfirmado,
    this.posicaoGlobalInicial,
    this.posicaoAmigosInicial,
    this.onBack,
  });

  // Cache curto em memória apenas na camada de tela (sem alterar ApiService)
  static const Duration _ttlCache = Duration(seconds: 45);
  static String? _cacheUsuarioLogadoId;
  static Map<String, dynamic>? _cacheGlobal;
  static DateTime? _cacheGlobalEm;
  static Map<String, dynamic>? _cacheAmigosLeaderboard;
  static DateTime? _cacheAmigosLeaderboardEm;
  static Map<String, dynamic>? _cacheListaAmigos;
  static DateTime? _cacheListaAmigosEm;

  static void invalidarCacheSocial() {
    _cacheGlobal = null;
    _cacheGlobalEm = null;
    _cacheAmigosLeaderboard = null;
    _cacheAmigosLeaderboardEm = null;
    _cacheListaAmigos = null;
    _cacheListaAmigosEm = null;
  }

  static bool _cacheValido(DateTime? em) {
    if (em == null) return false;
    return DateTime.now().difference(em) < _ttlCache;
  }

  static void _garantirMesmoUsuarioLogado() {
    final uidAtual = ApiService().idUsuarioAtual;
    if (_cacheUsuarioLogadoId != uidAtual) {
      invalidarCacheSocial();
      _cacheUsuarioLogadoId = uidAtual;
    }
  }

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  // ===========================================================================
  // DADOS DO AMIGO / ATLETA
  // ===========================================================================
  late String nomeUsuario;

  // Métricas de desempenho conectadas ao Supabase
  int pontosTotais = 0;
  int pontosHoje = 0;
  int pontosSemana = 0;
  int diasSequencia = 0;
  int maiorSequencia = 0;
  bool treinouHoje = false;

  // Posições nos Rankings e Status de Amizade
  int? posicaoGlobal;
  int? posicaoAmigos;
  bool _carregandoPerfil = true;
  bool _jaEhAmigo = false;
  bool _solicitacaoEnviada = false;
  bool _enviandoSolicitacao = false;
  bool _removendo = false;
  bool _alterouAmizade = false;

  @override
  void initState() {
    super.initState();
    final dados = widget.dadosIniciais;
    nomeUsuario = dados?['nome']?.toString().trim() ?? 'Atleta';
    diasSequencia = (dados?['sequencia'] as num?)?.toInt() ?? 0;
    maiorSequencia = (dados?['maior_sequencia'] as num?)?.toInt() ?? diasSequencia;
    if (diasSequencia > maiorSequencia) {
      maiorSequencia = diasSequencia;
    }
    pontosSemana = (dados?['pontos'] as num?)?.toInt() ??
        (dados?['pontuacao_semanal'] as num?)?.toInt() ??
        0;
    pontosTotais = (dados?['pontuacao_total'] as num?)?.toInt() ?? pontosSemana;
    pontosHoje = (dados?['pontuacao_diaria'] as num?)?.toInt() ?? 0;
    treinouHoje = (dados?['checagem'] == true) || pontosHoje > 0;
    posicaoGlobal = widget.posicaoGlobalInicial;
    posicaoAmigos = widget.posicaoAmigosInicial;
    _jaEhAmigo =
        widget.isAmigoConfirmado ??
        widget.isAmigoInicial ??
        (dados?['ja_amigo'] == true);
    _solicitacaoEnviada = dados?['solicitacao_enviada'] == true;
    _carregarPerfil(mostrarLoading: true, forcarAtualizacao: false);
  }

  Future<Map<String, dynamic>> _obterGlobalOtimizado({
    required bool forcarAtualizacao,
  }) async {
    FriendProfileScreen._garantirMesmoUsuarioLogado();
    if (!forcarAtualizacao &&
        FriendProfileScreen._cacheGlobal != null &&
        FriendProfileScreen._cacheValido(FriendProfileScreen._cacheGlobalEm)) {
      return FriendProfileScreen._cacheGlobal!;
    }
    final res = await ApiService().obterLeaderboardGlobal(limite: 100);
    if (res['sucesso'] == true && res['leaderboard'] is List) {
      FriendProfileScreen._cacheGlobal = res;
      FriendProfileScreen._cacheGlobalEm = DateTime.now();
    }
    return res;
  }

  Future<Map<String, dynamic>> _obterAmigosLeaderboardOtimizado({
    required bool forcarAtualizacao,
  }) async {
    FriendProfileScreen._garantirMesmoUsuarioLogado();
    if (!forcarAtualizacao &&
        FriendProfileScreen._cacheAmigosLeaderboard != null &&
        FriendProfileScreen._cacheValido(
          FriendProfileScreen._cacheAmigosLeaderboardEm,
        )) {
      return FriendProfileScreen._cacheAmigosLeaderboard!;
    }
    final res = await ApiService().obterLeaderboardAmigos();
    if (res['sucesso'] == true && res['leaderboard'] is List) {
      FriendProfileScreen._cacheAmigosLeaderboard = res;
      FriendProfileScreen._cacheAmigosLeaderboardEm = DateTime.now();
    }
    return res;
  }

  Future<Map<String, dynamic>> _obterListaAmigosOtimizado({
    required bool forcarAtualizacao,
  }) async {
    FriendProfileScreen._garantirMesmoUsuarioLogado();
    if (!forcarAtualizacao &&
        FriendProfileScreen._cacheListaAmigos != null &&
        FriendProfileScreen._cacheValido(
          FriendProfileScreen._cacheListaAmigosEm,
        )) {
      return FriendProfileScreen._cacheListaAmigos!;
    }
    final res = await ApiService().listarAmigos();
    if (res['sucesso'] == true && res['amigos'] is List) {
      FriendProfileScreen._cacheListaAmigos = res;
      FriendProfileScreen._cacheListaAmigosEm = DateTime.now();
    }
    return res;
  }

  Future<void> _carregarPerfil({
    bool mostrarLoading = false,
    bool forcarAtualizacao = false,
  }) async {
    final idAlvo = widget.amigoId.trim();
    if (idAlvo.isEmpty) {
      if (mounted && _carregandoPerfil) {
        setState(() => _carregandoPerfil = false);
      }
      return;
    }

    if (mostrarLoading && mounted && !_carregandoPerfil) {
      setState(() => _carregandoPerfil = true);
    }

    // Aproveita dados já conhecidos pela tela anterior na abertura inicial
    final bool statusAmizadeJaConfirmado =
        !forcarAtualizacao && widget.isAmigoConfirmado != null;
    final bool precisaBuscarGlobal =
        forcarAtualizacao || widget.posicaoGlobalInicial == null;
    final bool precisaBuscarAmigosLeaderboard =
        forcarAtualizacao ||
        (statusAmizadeJaConfirmado
            ? (widget.isAmigoConfirmado == true &&
                widget.posicaoAmigosInicial == null)
            : true);
    final bool precisaBuscarListaAmigos =
        forcarAtualizacao || !statusAmizadeJaConfirmado;

    try {
      final results = await Future.wait<Map<String, dynamic>?>([
        ApiService().verPerfil(idAlvo),
        precisaBuscarGlobal
            ? _obterGlobalOtimizado(forcarAtualizacao: forcarAtualizacao)
            : Future.value(null),
        precisaBuscarAmigosLeaderboard
            ? _obterAmigosLeaderboardOtimizado(
                forcarAtualizacao: forcarAtualizacao,
              )
            : Future.value(null),
        precisaBuscarListaAmigos
            ? _obterListaAmigosOtimizado(forcarAtualizacao: forcarAtualizacao)
            : Future.value(null),
      ]);

      if (!mounted) return;

      final resPerfil = results[0];
      final resGlobal = results[1];
      final resAmigos = results[2];
      final resListaAmigos = results[3];

      setState(() {
        if (resPerfil != null &&
            resPerfil['sucesso'] == true &&
            resPerfil['perfil'] != null) {
          final perfil = resPerfil['perfil'] as Map<String, dynamic>;
          if (perfil['nome'] != null &&
              perfil['nome'].toString().trim().isNotEmpty) {
            nomeUsuario = perfil['nome'].toString().trim();
          }
          pontosTotais =
              (perfil['pontuacao_total'] as num?)?.toInt() ?? pontosTotais;
          pontosHoje = (perfil['pontuacao_diaria'] as num?)?.toInt() ?? 0;
          pontosSemana =
              (perfil['pontuacao_semanal'] as num?)?.toInt() ?? pontosSemana;
          diasSequencia =
              (perfil['sequencia'] as num?)?.toInt() ?? diasSequencia;
          final recordeApi =
              (perfil['maior_sequencia'] as num?)?.toInt() ?? diasSequencia;
          maiorSequencia =
              diasSequencia > recordeApi ? diasSequencia : recordeApi;
          treinouHoje = (perfil['checagem'] == true) || pontosHoje > 0;
        }

        if (resGlobal != null &&
            resGlobal['sucesso'] == true &&
            resGlobal['leaderboard'] is List) {
          int? novaPosicaoGlobal;
          final listaGlobal = resGlobal['leaderboard'] as List;
          for (int i = 0; i < listaGlobal.length; i++) {
            final item = listaGlobal[i];
            if (item is Map && item['id']?.toString().trim() == idAlvo) {
              novaPosicaoGlobal = (item['posicao'] as num?)?.toInt() ?? (i + 1);
              break;
            }
          }
          posicaoGlobal = novaPosicaoGlobal;
        }

        if (statusAmizadeJaConfirmado) {
          _jaEhAmigo = widget.isAmigoConfirmado!;
          if (!_jaEhAmigo) {
            posicaoAmigos = null;
          } else if (resAmigos != null &&
              resAmigos['sucesso'] == true &&
              resAmigos['leaderboard'] is List) {
            int? novaPosicaoAmigos;
            final listaAmigos = resAmigos['leaderboard'] as List;
            for (int i = 0; i < listaAmigos.length; i++) {
              final item = listaAmigos[i];
              if (item is Map && item['id']?.toString().trim() == idAlvo) {
                novaPosicaoAmigos =
                    (item['posicao'] as num?)?.toInt() ?? (i + 1);
                break;
              }
            }
            posicaoAmigos = novaPosicaoAmigos;
          }
        } else {
          bool encontradoNosAmigos = false;
          int? novaPosicaoAmigos;
          if (resAmigos != null &&
              resAmigos['sucesso'] == true &&
              resAmigos['leaderboard'] is List) {
            final listaAmigos = resAmigos['leaderboard'] as List;
            for (int i = 0; i < listaAmigos.length; i++) {
              final item = listaAmigos[i];
              if (item is Map && item['id']?.toString().trim() == idAlvo) {
                novaPosicaoAmigos =
                    (item['posicao'] as num?)?.toInt() ?? (i + 1);
                encontradoNosAmigos = true;
                break;
              }
            }
          }

          if (resListaAmigos != null &&
              resListaAmigos['sucesso'] == true &&
              resListaAmigos['amigos'] is List) {
            final lista = resListaAmigos['amigos'] as List;
            for (final item in lista) {
              if (item is Map && item['id']?.toString().trim() == idAlvo) {
                encontradoNosAmigos = true;
                break;
              }
            }
          }

          if ((resAmigos != null && resAmigos['sucesso'] == true) ||
              (resListaAmigos != null && resListaAmigos['sucesso'] == true)) {
            _jaEhAmigo = encontradoNosAmigos;
            posicaoAmigos = encontradoNosAmigos ? novaPosicaoAmigos : null;
          }
        }

        _carregandoPerfil = false;
      });
    } catch (_) {
      if (mounted && _carregandoPerfil) {
        setState(() => _carregandoPerfil = false);
      }
    }
  }

  Future<void> _enviarSolicitacaoAmizade() async {
    final idAlvo = widget.amigoId.trim();
    if (idAlvo.isEmpty || _enviandoSolicitacao || _solicitacaoEnviada) return;

    setState(() => _enviandoSolicitacao = true);
    final res = await ApiService().enviarSolicitacaoAmizade(idAlvo);
    if (!mounted) return;
    setState(() => _enviandoSolicitacao = false);

    if (res['sucesso'] == true) {
      setState(() {
        _solicitacaoEnviada = true;
        _alterouAmizade = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['mensagem']?.toString() ??
                'Solicitação de amizade enviada para $nomeUsuario!',
          ),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['mensagem']?.toString() ?? 'Erro ao enviar solicitação.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _iniciarTreinoComAmigo() async {
    final idAlvo = widget.amigoId.trim();
    if (idAlvo.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      ),
    );

    try {
      final res = await ApiService().convidarParaTreinoEmDupla(
        convidadoId: idAlvo,
      );

      if (mounted) Navigator.pop(context); // Fecha loading

      if (mounted) {
        if (res['sucesso'] == true && res['sessao_id'] != null) {
          final sessaoId = res['sessao_id'].toString();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyDuplaScreen(
                sessaoId: sessaoId,
                isHost: true,
                amigoNome: nomeUsuario,
                amigoId: idAlvo,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['mensagem']?.toString() ??
                    'Não foi possível convidar o amigo.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar convite: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _removerAmigo() async {
    final idAlvo = widget.amigoId.trim();
    if (idAlvo.isEmpty || _removendo) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232A),
        title: const Text(
          'Remover Amigo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja remover $nomeUsuario da sua lista de amigos?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _removendo = true);
      final res = await ApiService().removerAmigo(idAlvo);
      if (!mounted) return;
      setState(() => _removendo = false);

      if (res['sucesso'] == true) {
        FriendProfileScreen.invalidarCacheSocial();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nomeUsuario foi removido da sua lista.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['mensagem']?.toString() ?? 'Erro ao remover amigo.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final letraAvatar = nomeUsuario.trim().isNotEmpty
        ? nomeUsuario.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context, _alterouAmizade);
            }
          },
        ),
        title: GestureDetector(
          onTap: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context, _alterouAmizade);
            }
          },
          child: Text(
            _carregandoPerfil
                ? 'PERFIL'
                : (_jaEhAmigo ? 'PERFIL DO AMIGO' : 'PERFIL DO ATLETA'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: _carregandoPerfil
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00E676)),
                  SizedBox(height: 14),
                  Text(
                    'Carregando perfil...',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _carregarPerfil(
                mostrarLoading: false,
                forcarAtualizacao: true,
              ),
        color: const Color(0xFF00E676),
        backgroundColor: const Color(0xFF1E232A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card com dados do amigo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E232A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00E676),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF00E676)
                            .withValues(alpha: 0.15),
                        child: Text(
                          letraAvatar,
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nomeUsuario,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badge de status de treino de hoje (Ideia 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: treinouHoje
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: treinouHoje
                              ? const Color(0xFF00E676).withValues(alpha: 0.5)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            treinouHoje
                                ? Icons.local_fire_department
                                : Icons.schedule,
                            size: 16,
                            color: treinouHoje
                                ? const Color(0xFF00E676)
                                : Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              treinouHoje
                                  ? 'Já treinou hoje!'
                                  : 'Ainda não treinou hoje',
                              style: TextStyle(
                                color: treinouHoje
                                    ? const Color(0xFF00E676)
                                    : Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 16),
                    const Text(
                      'Desempenho atual',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pontosTotais pts',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Hoje', '$pontosHoje pts'),
                    _buildStatRow('Semana', '$pontosSemana pts'),
                    _buildStatRow(
                      'Sequência Atual',
                      '$diasSequencia ${diasSequencia == 1 ? "dia" : "dias"}',
                    ),
                    _buildStatRow(
                      'Maior Sequência (Recorde)',
                      '$maiorSequencia ${maiorSequencia == 1 ? "dia" : "dias"}',
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 16),
                    // Posições nos Rankings (Ideia 2)
                    Row(
                      children: [
                        Expanded(
                          child: _buildRankingBadge(
                            titulo: 'Ranking Global',
                            posicao: posicaoGlobal,
                            icone: Icons.public,
                            cor: const Color(0xFF29B6F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRankingBadge(
                            titulo: 'Entre Amigos',
                            posicao: posicaoAmigos,
                            icone: Icons.people_outline,
                            cor: const Color(0xFF00E676),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_jaEhAmigo) ...[
                // 1º Botão: Treinar em Dupla
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _iniciarTreinoComAmigo,
                    icon: const Icon(Icons.fitness_center, size: 20),
                    label: const Text('Treinar em Dupla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2º Botão: Remover Amigo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _removendo ? null : _removerAmigo,
                    icon: _removendo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          )
                        : const Icon(
                            Icons.person_remove_outlined,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                    label: const Text(
                      'Remover Amigo',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3139),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Botão para convidar/adicionar amigo caso ainda não seja amigo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_solicitacaoEnviada || _enviandoSolicitacao)
                        ? null
                        : _enviarSolicitacaoAmizade,
                    icon: _enviandoSolicitacao
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Icon(
                            _solicitacaoEnviada
                                ? Icons.check
                                : Icons.person_add_alt_1,
                            size: 20,
                          ),
                    label: Text(
                      _solicitacaoEnviada
                          ? 'Solicitação de Amizade Enviada'
                          : 'Convidar para ser Amigo',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: const Color(0xFF2D3139),
                      disabledForegroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingBadge({
    required String titulo,
    required int? posicao,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3139),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 15, color: cor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            posicao != null ? '#$posicao' : '-',
            style: TextStyle(
              color: cor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
