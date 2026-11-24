import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lobby_dupla_screen.dart';

class FriendProfileScreen extends StatefulWidget {
  final String amigoId;
  final Map<String, dynamic>? dadosIniciais;
  final bool? isAmigoInicial;
  final VoidCallback? onBack;

  const FriendProfileScreen({
    super.key,
    required this.amigoId,
    this.dadosIniciais,
    this.isAmigoInicial,
    this.onBack,
  });

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
  bool _jaEhAmigo = false;
  bool _solicitacaoEnviada = false;
  bool _enviandoSolicitacao = false;
  bool _removendo = false;
  bool _alterouAmizade = false;

  // Privacidade (Opção B) e Treinos Personalizados do Atleta
  bool _perfilPublico = true;
  bool _podeVisualizarTreinos = true;
  bool _carregandoTreinos = true;
  List<Map<String, dynamic>> _treinosAtleta = [];
  final Set<String> _treinosCopiadosIds = {};
  final Set<String> _treinosCopiandoIds = {};

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
    _jaEhAmigo = widget.isAmigoInicial ?? (dados?['ja_amigo'] == true);
    _solicitacaoEnviada = dados?['solicitacao_enviada'] == true;
    _perfilPublico = dados?['perfil_publico'] != false;
    _podeVisualizarTreinos = _perfilPublico || _jaEhAmigo;
    if (dados?['posicao'] is num) {
      posicaoGlobal = (dados!['posicao'] as num).toInt();
    }
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final idAlvo = widget.amigoId.trim();
    if (idAlvo.isEmpty) return;

    try {
      final results = await Future.wait([
        ApiService().verPerfil(idAlvo),
        ApiService().obterLeaderboardGlobal(limite: 100),
        ApiService().obterLeaderboardAmigos(),
        ApiService().listarAmigos(),
        ApiService().listarTreinosUsuario(idAlvo),
      ]);

      if (!mounted) return;

      final resPerfil = results[0];
      final resGlobal = results[1];
      final resAmigos = results[2];
      final resListaAmigos = results[3];
      final resTreinos = results[4];

      setState(() {
        bool? perfilPublicoRecebido;
        bool? jaAmigoPerfil;
        bool? podeVerPerfil;

        if (resPerfil['sucesso'] == true && resPerfil['perfil'] != null) {
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
          if (perfil.containsKey('perfil_publico')) {
            perfilPublicoRecebido = perfil['perfil_publico'] != false;
          }
          if (perfil.containsKey('ja_amigo')) {
            jaAmigoPerfil = perfil['ja_amigo'] == true;
          }
          if (perfil.containsKey('pode_visualizar_treinos')) {
            podeVerPerfil = perfil['pode_visualizar_treinos'] != false;
          }
        }

        if (resGlobal['sucesso'] == true && resGlobal['leaderboard'] is List) {
          final listaGlobal = resGlobal['leaderboard'] as List;
          for (int i = 0; i < listaGlobal.length; i++) {
            final item = listaGlobal[i];
            if (item is Map && item['id']?.toString().trim() == idAlvo) {
              posicaoGlobal = (item['posicao'] as num?)?.toInt() ?? (i + 1);
              break;
            }
          }
        }

        bool encontradoNosAmigos = jaAmigoPerfil == true;
        if (resAmigos['sucesso'] == true && resAmigos['leaderboard'] is List) {
          final listaAmigos = resAmigos['leaderboard'] as List;
          for (int i = 0; i < listaAmigos.length; i++) {
            final item = listaAmigos[i];
            if (item is Map && item['id']?.toString().trim() == idAlvo) {
              posicaoAmigos = (item['posicao'] as num?)?.toInt() ?? (i + 1);
              encontradoNosAmigos = true;
              break;
            }
          }
        }

        if (resListaAmigos['sucesso'] == true &&
            resListaAmigos['amigos'] is List) {
          final lista = resListaAmigos['amigos'] as List;
          for (final item in lista) {
            if (item is Map && item['id']?.toString().trim() == idAlvo) {
              encontradoNosAmigos = true;
              break;
            }
          }
        }

        if (resAmigos['sucesso'] == true ||
            resListaAmigos['sucesso'] == true ||
            jaAmigoPerfil != null) {
          _jaEhAmigo = encontradoNosAmigos;
          if (!encontradoNosAmigos) {
            posicaoAmigos = null;
          }
        }

        if (resTreinos.containsKey('perfil_publico')) {
          _perfilPublico = resTreinos['perfil_publico'] != false;
        } else if (perfilPublicoRecebido != null) {
          _perfilPublico = perfilPublicoRecebido;
        }

        // Regra Opção B: se o perfil é público OU se já são amigos confirmados, pode visualizar e copiar treinos
        final bool ocultoPorPrivacidade =
            resTreinos['treinos_ocultos_privacidade'] == true ||
                resTreinos['pode_visualizar_treinos'] == false ||
                podeVerPerfil == false;

        _podeVisualizarTreinos =
            (_perfilPublico || _jaEhAmigo || idAlvo == ApiService().idUsuarioAtual) &&
                !ocultoPorPrivacidade;

        if (_podeVisualizarTreinos && resTreinos['treinos'] is List) {
          _treinosAtleta = (resTreinos['treinos'] as List)
              .whereType<Map>()
              .map((t) => Map<String, dynamic>.from(t))
              .toList();
        } else if (!_podeVisualizarTreinos) {
          _treinosAtleta = [];
        }
        _carregandoTreinos = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _carregandoTreinos = false);
      }
    }
  }

  Future<void> _copiarTreinoParaMeusTreinos(Map<String, dynamic> treino) async {
    final idTreino = (treino['id'] ?? treino['nome'] ?? '').toString();
    if (_treinosCopiandoIds.contains(idTreino)) return;

    setState(() => _treinosCopiandoIds.add(idTreino));

    final res = await ApiService().copiarTreinoDeAtleta(
      treino: treino,
      donoOrigemId: widget.amigoId.trim(),
      nomeAutor: nomeUsuario,
    );

    if (!mounted) return;
    setState(() {
      _treinosCopiandoIds.remove(idTreino);
      if (res['sucesso'] == true) {
        _treinosCopiadosIds.add(idTreino);
      }
    });

    if (res['sucesso'] == true) {
      final nomeTreino = (treino['nome'] ?? treino['titulo'] ?? 'Treino').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Treino "$nomeTreino" copiado com sucesso para Meus Treinos!',
          ),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['mensagem']?.toString() ?? 'Não foi possível copiar o treino.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _exibirDetalhesTreino(Map<String, dynamic> treino) {
    final nomeTreino = (treino['nome'] ?? treino['titulo'] ?? 'Treino').toString();
    final dificuldade = (treino['dificuldade'] ?? 'Personalizado').toString();
    final duracao = (treino['duracao_minutos'] ?? treino['duracaoMinutos'] ?? 30).toString();
    final exercicios = (treino['exercicios'] is List)
        ? (treino['exercicios'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    final idTreino = (treino['id'] ?? nomeTreino).toString();
    final jaCopiado = _treinosCopiadosIds.contains(idTreino);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E232A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nomeTreino,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$dificuldade • $duracao min • ${exercicios.length} ${exercicios.length == 1 ? "exercício" : "exercícios"}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                  ),
                  child: exercicios.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Nenhum exercício listado neste treino.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: exercicios.length,
                          separatorBuilder: (_, _) =>
                              const Divider(color: Colors.white10, height: 12),
                          itemBuilder: (_, index) {
                            final ex = exercicios[index];
                            final nomeEx =
                                (ex['nome'] ?? 'Exercício ${index + 1}').toString();
                            final series = (ex['series'] ?? 3).toString();
                            final reps = (ex['repeticoes'] ?? 10).toString();
                            return Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF00E676),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nomeEx,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${series}x$reps',
                                  style: const TextStyle(
                                    color: Color(0xFF00E676),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: jaCopiado
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _copiarTreinoParaMeusTreinos(treino);
                          },
                    icon: Icon(
                      jaCopiado ? Icons.check : Icons.copy_rounded,
                      size: 18,
                    ),
                    label: Text(
                      jaCopiado ? 'Treino Já Copiado' : 'Copiar para Meus Treinos',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: const Color(0xFF2D3139),
                      disabledForegroundColor: const Color(0xFF00E676),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            _jaEhAmigo ? 'PERFIL DO AMIGO' : 'PERFIL DO ATLETA',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarPerfil,
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
                    // Badges de status de treino de hoje e de privacidade do perfil
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _perfilPublico
                                ? const Color(0xFF29B6F6).withValues(alpha: 0.12)
                                : Colors.amberAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _perfilPublico
                                  ? const Color(0xFF29B6F6).withValues(alpha: 0.45)
                                  : Colors.amberAccent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _perfilPublico ? Icons.public : Icons.lock_outline,
                                size: 14,
                                color: _perfilPublico
                                    ? const Color(0xFF29B6F6)
                                    : Colors.amberAccent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _perfilPublico
                                    ? 'Perfil Público'
                                    : 'Privado • Amigos',
                                style: TextStyle(
                                  color: _perfilPublico
                                      ? const Color(0xFF29B6F6)
                                      : Colors.amberAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    // Posições nos Rankings
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

              // ===============================================================
              // SEÇÃO: TREINOS PERSONALIZADOS DO ATLETA (COPIAR TREINO)
              // ===============================================================
              _buildSecaoTreinosAtleta(),

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

  Widget _buildSecaoTreinosAtleta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: Color(0xFF00E676),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Treinos de $nomeUsuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_podeVisualizarTreinos && !_carregandoTreinos)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_treinosAtleta.length}',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_carregandoTreinos)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00E676),
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (!_podeVisualizarTreinos)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3139),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.amberAccent,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Treinos Visíveis Apenas para Amigos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$nomeUsuario configurou o perfil como privado. Adicione como amigo para visualizar e copiar seus treinos personalizados!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else if (_treinosAtleta.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3139),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Este atleta ainda não cadastrou treinos personalizados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 13.5),
              ),
            )
          else
            Column(
              children: _treinosAtleta.map(_buildCardTreinoAtleta).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCardTreinoAtleta(Map<String, dynamic> treino) {
    final nomeTreino =
        (treino['nome'] ?? treino['titulo'] ?? 'Treino Personalizado')
            .toString();
    final dificuldade = (treino['dificuldade'] ?? 'Personalizado').toString();
    final duracao =
        (treino['duracao_minutos'] ?? treino['duracaoMinutos'] ?? 30)
            .toString();
    final exercicios = (treino['exercicios'] is List)
        ? (treino['exercicios'] as List).whereType<Map>().toList()
        : <Map>[];
    final qtdExercicios =
        (treino['exerciciosCount'] as num?)?.toInt() ?? exercicios.length;
    final idTreino = (treino['id'] ?? nomeTreino).toString();
    final estaCopiando = _treinosCopiandoIds.contains(idTreino);
    final jaCopiado = _treinosCopiadosIds.contains(idTreino);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3139),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _exibirDetalhesTreino(treino),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeTreino,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dificuldade • $duracao min • $qtdExercicios ${qtdExercicios == 1 ? "exercício" : "exercícios"}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: (estaCopiando || jaCopiado)
                    ? null
                    : () => _copiarTreinoParaMeusTreinos(treino),
                icon: estaCopiando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Icon(
                        jaCopiado ? Icons.check : Icons.copy_rounded,
                        size: 16,
                      ),
                label: Text(
                  jaCopiado ? 'Copiado' : 'Copiar',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: jaCopiado
                      ? const Color(0xFF00E676).withValues(alpha: 0.2)
                      : Colors.white12,
                  disabledForegroundColor:
                      jaCopiado ? const Color(0xFF00E676) : Colors.white54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          if (exercicios.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...exercicios.take(3).map((ex) {
                  final nomeEx = (ex['nome'] ?? 'Exercício').toString();
                  final s = ex['series'] ?? 3;
                  final r = ex['repeticoes'] ?? 10;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E232A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$nomeEx (${s}x$r)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  );
                }),
                if (exercicios.length > 3)
                  GestureDetector(
                    onTap: () => _exibirDetalhesTreino(treino),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${exercicios.length - 3} ver todos',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
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
