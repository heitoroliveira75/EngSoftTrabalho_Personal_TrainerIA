import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'amigos_screen.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'training_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSecondRoute;

  const HomeScreen({super.key, this.onSecondRoute});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS E NAVEGAÇÃO
  // ===========================================================================
  int _abaSelecionada =
      0; // 0 = Home, 1 = Amigos, 2 = Treinar, 3 = Leaderboard, 4 = Perfil
  String nomeUsuario = 'Atleta';
  int pontosTotais = 0;
  int pontosSemana = 0;
  int maiorSequencia = 0;
  int sequenciaAtual = 0;
  int pontosHoje = 0;
  int metaHoje = 200;

  @override
  void initState() {
    super.initState();
    nomeUsuario = ApiService().nomeUsuarioAtual;
    pontosTotais = ApiService().pontuacaoTotalAtual;
    pontosSemana = ApiService().pontuacaoSemanalAtual;
    pontosHoje = ApiService().pontuacaoDiariaAtual;
    sequenciaAtual = ApiService().sequenciaAtual;
    maiorSequencia = ApiService().maiorSequenciaAtual;
    if (sequenciaAtual > maiorSequencia) {
      maiorSequencia = sequenciaAtual;
    }
    _carregarPontuacoes();
  }

  Future<void> _carregarPontuacoes() async {
    var usuarioId = ApiService().idUsuarioAtual;
    if (usuarioId == null) {
      final userRes = await ApiService().obterUsuarioAtual();
      if (userRes['sessao_encerrada'] == true && mounted) {
        _redirecionarSessaoEncerrada(userRes['mensagem']?.toString());
        return;
      }
      if (userRes['sucesso'] == true && ApiService().idUsuarioAtual != null) {
        usuarioId = ApiService().idUsuarioAtual;
      }
    }

    if (usuarioId != null) {
      final res = await ApiService().verPontuacao(usuarioId);
      if (res['sessao_encerrada'] == true && mounted) {
        _redirecionarSessaoEncerrada(res['mensagem']?.toString());
        return;
      }
      if (mounted && res['sucesso'] == true) {
        setState(() {
          if (res['nome'] != null && res['nome'].toString().trim().isNotEmpty) {
            nomeUsuario = res['nome'].toString().trim();
          } else {
            nomeUsuario = ApiService().nomeUsuarioAtual;
          }
          pontosTotais = (res['pontuacao_total'] as num?)?.toInt() ?? 0;
          pontosSemana = (res['pontuacao_semanal'] as num?)?.toInt() ?? 0;
          pontosHoje = (res['pontuacao_diaria'] as num?)?.toInt() ?? 0;
          sequenciaAtual =
              (res['sequencia'] as num?)?.toInt() ??
              (res['pontuacoes'] is Map
                  ? (res['pontuacoes']['sequencia'] as num?)?.toInt()
                  : null) ??
              ApiService().sequenciaAtual;
          maiorSequencia =
              (res['maior_sequencia'] as num?)?.toInt() ??
              (res['pontuacoes'] is Map
                  ? (res['pontuacoes']['maior_sequencia'] as num?)?.toInt()
                  : null) ??
              ApiService().maiorSequenciaAtual;
          if (sequenciaAtual > maiorSequencia) {
            maiorSequencia = sequenciaAtual;
          }
        });
      }
    }
  }

  void _redirecionarSessaoEncerrada(String? mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem ?? 'Sua conta foi conectada em outro dispositivo.',
        ),
        backgroundColor: Colors.orangeAccent,
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _iniciarTreino() {
    if (widget.onSecondRoute != null) {
      widget.onSecondRoute!();
    } else {
      _mudarAba(2); // Alterna diretamente para a aba Treinar
    }
  }

  void _mudarAba(int index) {
    setState(() {
      _abaSelecionada = index;
    });
    if (index == 0) {
      _carregarPontuacoes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> telas = [
      _buildAbaInicio(),
      AmigosScreen(
        onBack: () => _mudarAba(0),
        onOpenLeaderboard: () => _mudarAba(3),
      ),
      TrainingMenuScreen(onBack: () => _mudarAba(0)),
      LeaderboardScreen(
        onBack: () => _mudarAba(0),
        onOpenAmigos: () => _mudarAba(1),
      ),
      ProfileScreen(onBack: () => _mudarAba(0)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: _abaSelecionada == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'HOME',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              actions: [
                // Ícone de perfil que navega para a aba de Perfil
                IconButton(
                  icon: const Icon(
                    Icons.account_circle,
                    size: 34,
                    color: Colors.white,
                  ),
                  tooltip: 'Meu Perfil',
                  onPressed: () => _mudarAba(4),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: telas[_abaSelecionada],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _abaSelecionada,
          onTap: (int index) => _mudarAba(index),
          backgroundColor: const Color(0xFF161B22),
          selectedItemColor: const Color(0xFF00E676),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Amigos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center_rounded),
              label: 'Treinar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              activeIcon: Icon(Icons.leaderboard_rounded),
              label: 'Ranking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbaInicio() {
    return RefreshIndicator(
      onRefresh: _carregarPontuacoes,
      color: const Color(0xFF00E676),
      backgroundColor: const Color(0xFF1E232A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Saudação do Usuário (isolada por sessão local, sem consultar estado global)
            Builder(
              builder: (context) {
                final nome =
                    (nomeUsuario.isNotEmpty && nomeUsuario != 'Usuário')
                    ? nomeUsuario
                    : ApiService().nomeUsuarioAtual;
                final primeiroNome = nome.isNotEmpty
                    ? nome.split(' ')[0]
                    : 'Atleta';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $primeiroNome 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pronto para o treino de hoje?',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                );
              },
            ),

            // Espaçamento
            const SizedBox(height: 24),

            // 2. Cards de Métricas em Row (altura uniforme)
            // 2. Cards de Métricas em Row (com Altura Igual)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Pontos da Semana
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.star,
                      iconColor: const Color(0xFF00E676),
                      value: '$pontosSemana',
                      label: 'Pontos Semana',
                      labelColor: const Color(0xFF00E676),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Card Sequência Atual
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.bolt,
                      iconColor: const Color(0xFFFFD700),
                      value: '$sequenciaAtual',
                      label: 'Dias Seguidos',
                      labelColor: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Card Recorde de Sequência
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.local_fire_department,
                      iconColor: const Color(0xFFFF5252),
                      value: '$maiorSequencia',
                      label: 'Recorde Dias',
                      labelColor: const Color(0xFFFF5252),
                    ),
                  ),
                ],
              ),
            ),

            // Espaçamento
            const SizedBox(height: 24),

            // 3. Card Meta de Hoje
            Container(
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
                  const Text(
                    'Meta de Hoje',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '$pontosHoje/$metaHoje pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: metaHoje > 0
                          ? (pontosHoje / metaHoje).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 16,
                      backgroundColor: const Color(0xFF2D3139),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Espaçamento
            const SizedBox(height: 24),

            // 4. Botão Hora de Treinar
            InkWell(
              onTap: _iniciarTreino,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E232A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 56,
                      color: Color(0xFF00E676),
                    ),
                    const SizedBox(width: 16),
                    Container(height: 50, width: 2, color: Colors.white12),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hora de',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Treinar',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF00E676),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 44,
            child: Center(child: Icon(icon, size: 44, color: iconColor)),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: labelColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
