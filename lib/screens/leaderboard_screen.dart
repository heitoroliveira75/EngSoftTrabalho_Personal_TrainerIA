import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'amigos_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _carregando = false;
  String? _erroMensagem;

  List<Map<String, dynamic>> _globalLeaderboard = [];
  List<Map<String, dynamic>> _amigosLeaderboard = [];
  int? _minhaPosicaoGlobal;
  int? _minhaPosicaoAmigos;
  int _meusPontos = 0;
  int _minhaSequencia = 0;

  // Critério de ordenação ativo: 'pontos' (Pontuação Semanal) ou 'streak' (Sequência de Dias)
  String _criterioOrdenacao = 'pontos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _minhaSequencia = ApiService().sequenciaAtual;
    _carregarLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Retorna uma cópia ordenada da lista com base no critério selecionado e recalcula posições ordinais
  List<Map<String, dynamic>> _obterItensOrdenados(List<Map<String, dynamic>> listaOriginal) {
    final List<Map<String, dynamic>> copia = List<Map<String, dynamic>>.from(
      listaOriginal.map((e) => Map<String, dynamic>.from(e)),
    );

    copia.sort((a, b) {
      if (_criterioOrdenacao == 'streak') {
        final streakA = (a['sequencia'] as num?)?.toInt() ?? 0;
        final streakB = (b['sequencia'] as num?)?.toInt() ?? 0;
        if (streakB != streakA) return streakB.compareTo(streakA);
        final pontosA = (a['pontos'] as num?)?.toInt() ?? 0;
        final pontosB = (b['pontos'] as num?)?.toInt() ?? 0;
        return pontosB.compareTo(pontosA);
      } else {
        final pontosA = (a['pontos'] as num?)?.toInt() ?? 0;
        final pontosB = (b['pontos'] as num?)?.toInt() ?? 0;
        if (pontosB != pontosA) return pontosB.compareTo(pontosA);
        final streakA = (a['sequencia'] as num?)?.toInt() ?? 0;
        final streakB = (b['sequencia'] as num?)?.toInt() ?? 0;
        return streakB.compareTo(streakA);
      }
    });

    for (int i = 0; i < copia.length; i++) {
      copia[i]['posicao'] = i + 1;
    }

    return copia;
  }

  int? _obterMinhaPosicaoOrdenada(List<Map<String, dynamic>> itensOrdenados) {
    final idx = itensOrdenados.indexWhere((it) => it['is_me'] == true);
    return idx != -1 ? idx + 1 : null;
  }

  Future<void> _carregarLeaderboard() async {
    setState(() {
      _carregando = true;
      _erroMensagem = null;
    });

    final meuId = ApiService().idUsuarioAtual;

    try {
      // 1. Leaderboard Global
      final resGlobal = await ApiService().obterLeaderboardGlobal(limite: 50);

      // 2. Leaderboard Amigos
      final resAmigos = await ApiService().obterLeaderboardAmigos();

      // 3. Minha Posição Global
      final resPosicao = await ApiService().obterMinhaPosicaoGlobal();

      // 4. Meus Pontos / Sequência atualizada
      if (meuId != null) {
        final resPontos = await ApiService().verPontuacao(meuId);
        if (resPontos['sucesso'] == true) {
          _meusPontos = (resPontos['pontuacao_semanal'] as num?)?.toInt() ??
              (resPontos['pontuacao_total'] as num?)?.toInt() ??
              0;
          _minhaSequencia = (resPontos['sequencia'] as num?)?.toInt() ??
              ApiService().sequenciaAtual;
        }
      }

      if (mounted) {
        setState(() {
          // Processar Global
          if (resGlobal['sucesso'] == true && resGlobal['leaderboard'] is List) {
            final lista = resGlobal['leaderboard'] as List;
            _globalLeaderboard = lista.map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              final isMe = meuId != null &&
                  map['id'] != null &&
                  map['id'].toString().trim() == meuId.trim();
              return {
                'posicao': (map['posicao'] as num?)?.toInt() ?? 1,
                'id': map['id']?.toString() ?? '',
                'nome': isMe ? 'Você' : (map['nome']?.toString() ?? 'Atleta'),
                'pontos': (map['pontos'] as num?)?.toInt() ??
                    (map['pontuacao_semanal'] as num?)?.toInt() ??
                    0,
                'sequencia': (map['sequencia'] as num?)?.toInt() ?? 0,
                'is_me': isMe,
              };
            }).toList();
          }

          // Processar Amigos
          if (resAmigos['sucesso'] == true && resAmigos['leaderboard'] is List) {
            final lista = resAmigos['leaderboard'] as List;
            _amigosLeaderboard = lista.map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              final isMe = (map['is_me'] == true) ||
                  (meuId != null &&
                      map['id'] != null &&
                      map['id'].toString().trim() == meuId.trim());
              return {
                'posicao': (map['posicao'] as num?)?.toInt() ?? 1,
                'id': map['id']?.toString() ?? '',
                'nome': isMe ? 'Você' : (map['nome']?.toString() ?? 'Amigo'),
                'pontos': (map['pontos'] as num?)?.toInt() ??
                    (map['pontuacao_semanal'] as num?)?.toInt() ??
                    0,
                'sequencia': (map['sequencia'] as num?)?.toInt() ?? 0,
                'is_me': isMe,
              };
            }).toList();

            // Calcular minha posição entre amigos
            final indexAmigos = _amigosLeaderboard.indexWhere((it) => it['is_me'] == true);
            if (indexAmigos != -1) {
              _minhaPosicaoAmigos = _amigosLeaderboard[indexAmigos]['posicao'] as int?;
            }
          }

          // Processar Posição Global
          if (resPosicao['sucesso'] == true && resPosicao['posicao'] != null) {
            _minhaPosicaoGlobal = (resPosicao['posicao'] as num?)?.toInt();
          } else {
            final indexGlobal = _globalLeaderboard.indexWhere((it) => it['is_me'] == true);
            if (indexGlobal != -1) {
              _minhaPosicaoGlobal = _globalLeaderboard[indexGlobal]['posicao'] as int?;
            }
          }

          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erroMensagem = 'Falha ao conectar à API: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomeUsuario = ApiService().nomeUsuarioAtual;

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
          'CLASSIFICAÇÃO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: Color(0xFF00E676)),
            tooltip: 'Gerenciar Amigos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AmigosScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Atualizar',
            onPressed: _carregarLeaderboard,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(
              icon: Icon(Icons.public),
              text: 'Global',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Amigos',
            ),
          ],
        ),
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardTab(
                  titulo: 'Ranking Global Semanal',
                  subtitulo: 'Compita com atletas de toda a comunidade',
                  itens: _globalLeaderboard,
                  minhaPosicao: _minhaPosicaoGlobal,
                  nomeUsuario: nomeUsuario,
                ),
                _buildLeaderboardTab(
                  titulo: 'Ranking Entre Amigos',
                  subtitulo: 'Veja quem está liderando entre suas conexões',
                  itens: _amigosLeaderboard,
                  minhaPosicao: _minhaPosicaoAmigos,
                  nomeUsuario: nomeUsuario,
                  isAmigosTab: true,
                ),
              ],
            ),
    );
  }

  Widget _buildLeaderboardTab({
    required String titulo,
    required String subtitulo,
    required List<Map<String, dynamic>> itens,
    required int? minhaPosicao,
    required String nomeUsuario,
    bool isAmigosTab = false,
  }) {
    final itensOrdenados = _obterItensOrdenados(itens);
    final posicaoEfetiva = _obterMinhaPosicaoOrdenada(itensOrdenados) ?? minhaPosicao;

    return RefreshIndicator(
      onRefresh: _carregarLeaderboard,
      color: const Color(0xFF00E676),
      backgroundColor: const Color(0xFF1E232A),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (_erroMensagem != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(
                _erroMensagem!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),

          // Banner descritivo da aba
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF00E676),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Seletor de Critério de Ranking (Pontuação Semanal vs Streak)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_criterioOrdenacao != 'pontos') {
                        setState(() => _criterioOrdenacao = 'pontos');
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _criterioOrdenacao == 'pontos'
                            ? const Color(0xFF00E676)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            size: 15,
                            color: _criterioOrdenacao == 'pontos'
                                ? const Color(0xFF0D1117)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pontuação Semanal',
                            style: TextStyle(
                              color: _criterioOrdenacao == 'pontos'
                                  ? const Color(0xFF0D1117)
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_criterioOrdenacao != 'streak') {
                        setState(() => _criterioOrdenacao = 'streak');
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _criterioOrdenacao == 'streak'
                            ? const Color(0xFF00E676)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 16,
                            color: _criterioOrdenacao == 'streak'
                                ? const Color(0xFF0D1117)
                                : Colors.amberAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Streak de Treinos',
                            style: TextStyle(
                              color: _criterioOrdenacao == 'streak'
                                  ? const Color(0xFF0D1117)
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card de Posição do Usuário Atual (Real)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D3139), Color(0xFF1E232A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    posicaoEfetiva != null ? '#$posicaoEfetiva' : '-',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sua Posição Atual',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        nomeUsuario,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFF00E676)),
                        const SizedBox(width: 3),
                        Text(
                          '$_meusPontos pts sem.',
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 2),
                        Text(
                          '$_minhaSequencia dias streak',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pódio dos 3 primeiros (se houver pelo menos 3)
          if (itensOrdenados.length >= 3) _buildPodium(itensOrdenados),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tabela Completa',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _criterioOrdenacao == 'streak'
                    ? 'Ordenado por Streak'
                    : 'Ordenado por Pontos Semanais',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Se a lista estiver vazia
          if (itensOrdenados.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.leaderboard_outlined, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    isAmigosTab
                        ? 'Nenhum amigo adicionado ainda.\nAdicione amigos para disputar o ranking!'
                        : 'Nenhum atleta registrado na pontuação semanal ainda.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...itensOrdenados.map((item) => _buildLeaderboardTile(item)),

          if (isAmigosTab) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AmigosScreen()),
                ).then((_) => _carregarLeaderboard());
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Convidar / Buscar Amigos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: const Color(0xFF0D1117),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> itens) {
    final primeiro = itens[0];
    final segundo = itens[1];
    final terceiro = itens[2];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2º Lugar
          _buildPodiumStep(
            posicao: 2,
            nome: segundo['nome'] as String,
            pontos: (segundo['pontos'] as num).toInt(),
            sequencia: (segundo['sequencia'] as num).toInt(),
            cor: const Color(0xFFC0C0C0), // Prata
            altura: 75,
          ),
          // 1º Lugar
          _buildPodiumStep(
            posicao: 1,
            nome: primeiro['nome'] as String,
            pontos: (primeiro['pontos'] as num).toInt(),
            sequencia: (primeiro['sequencia'] as num).toInt(),
            cor: const Color(0xFFFFD700), // Ouro
            altura: 100,
          ),
          // 3º Lugar
          _buildPodiumStep(
            posicao: 3,
            nome: terceiro['nome'] as String,
            pontos: (terceiro['pontos'] as num).toInt(),
            sequencia: (terceiro['sequencia'] as num).toInt(),
            cor: const Color(0xFFCD7F32), // Bronze
            altura: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required int posicao,
    required String nome,
    required int pontos,
    required int sequencia,
    required Color cor,
    required double altura,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.workspace_premium, color: cor, size: 28),
        const SizedBox(height: 4),
        SizedBox(
          width: 85,
          child: Text(
            nome,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Pontuação Semanal
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 11, color: cor),
            const SizedBox(width: 2),
            Text(
              '$pontos pts',
              style: TextStyle(
                color: cor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Streak
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 11, color: Colors.amberAccent),
            Text(
              '$sequencia d streak',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: altura,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: cor.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$posicao',
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> item) {
    final bool isMe = item['is_me'] == true;
    final int posicao = (item['posicao'] as num).toInt();
    final int pontos = (item['pontos'] as num).toInt();
    final int sequencia = (item['sequencia'] as num).toInt();

    Color badgeColor;
    if (posicao == 1) {
      badgeColor = const Color(0xFFFFD700);
    } else if (posicao == 2) {
      badgeColor = const Color(0xFFC0C0C0);
    } else if (posicao == 3) {
      badgeColor = const Color(0xFFCD7F32);
    } else {
      badgeColor = Colors.white54;
    }

    final nome = item['nome']?.toString() ?? 'Atleta';
    final letraAvatar = nome.isNotEmpty ? nome[0].toUpperCase() : 'A';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF00E676).withValues(alpha: 0.12) : const Color(0xFF2D3139),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe ? const Color(0xFF00E676) : Colors.white10,
          width: isMe ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$posicao',
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? const Color(0xFF00E676) : const Color(0xFF1E232A),
            child: Text(
              letraAvatar,
              style: TextStyle(
                color: isMe ? const Color(0xFF0D1117) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nome,
                        style: TextStyle(
                          color: isMe ? const Color(0xFF00E676) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VOCÊ',
                          style: TextStyle(
                            color: Color(0xFF0D1117),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 2),
                    Text(
                      '$sequencia dias streak',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 13, color: Color(0xFF00E676)),
                    const SizedBox(width: 2),
                    Text(
                      '$pontos pts sem.',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _criterioOrdenacao == 'streak' ? '$sequencia d' : '$pontos pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                _criterioOrdenacao == 'streak' ? '$pontos pts sem.' : '$sequencia d streak',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
