import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'leaderboard_screen.dart';

class AmigosScreen extends StatefulWidget {
  const AmigosScreen({super.key});

  @override
  State<AmigosScreen> createState() => _AmigosScreenState();
}

class _AmigosScreenState extends State<AmigosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  Timer? _debounceTimer;

  bool _carregando = false;
  bool _buscando = false;
  String? _erroMensagem;

  List<Map<String, dynamic>> _meusAmigos = [];
  List<Map<String, dynamic>> _solicitacoesPendentes = [];
  List<Map<String, dynamic>> _resultadosBusca = [];
  bool _buscou = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarAmigos();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarAmigos() async {
    setState(() {
      _carregando = true;
      _erroMensagem = null;
    });

    try {
      final resAmigos = await ApiService().listarAmigos();
      final resPendentes = await ApiService().listarSolicitacoesPendentes();

      if (mounted) {
        setState(() {
          if (resAmigos['sucesso'] == true && resAmigos['amigos'] is List) {
            _meusAmigos = List<Map<String, dynamic>>.from(
              (resAmigos['amigos'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }

          if (resPendentes['sucesso'] == true && resPendentes['solicitacoes'] is List) {
            _solicitacoesPendentes = List<Map<String, dynamic>>.from(
              (resPendentes['solicitacoes'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }

          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erroMensagem = 'Erro ao carregar dados: $e';
        });
      }
    }
  }

  void _aoDigitarBusca(String termo) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executarBusca(termo);
    });
  }

  Future<void> _executarBusca(String termo) async {
    if (termo.trim().isEmpty) {
      setState(() {
        _resultadosBusca = [];
        _buscou = false;
        _buscando = false;
      });
      return;
    }

    setState(() {
      _buscando = true;
      _buscou = true;
    });

    try {
      final res = await ApiService().buscarUsuarios(termo.trim());
      if (mounted) {
        setState(() {
          _buscando = false;
          if (res['sucesso'] == true && res['usuarios'] is List) {
            _resultadosBusca = List<Map<String, dynamic>>.from(
              (res['usuarios'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
            );
          } else {
            _resultadosBusca = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buscando = false;
          _resultadosBusca = [];
        });
      }
    }
  }

  Future<void> _enviarSolicitacao(String amigoId, String nome) async {
    final res = await ApiService().enviarSolicitacaoAmizade(amigoId);

    if (!mounted) return;

    if (res['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensagem']?.toString() ?? 'Solicitação de amizade enviada para $nome!'),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
      setState(() {
        final index = _resultadosBusca.indexWhere((u) => u['id']?.toString() == amigoId);
        if (index != -1) {
          _resultadosBusca[index]['solicitacao_enviada'] = true;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensagem']?.toString() ?? 'Erro ao enviar solicitação.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _aceitarSolicitacao(String solicitacaoId, String nome) async {
    final res = await ApiService().responderSolicitacao(solicitacaoId, 'aceito');

    if (!mounted) return;

    if (res['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você e $nome agora são amigos!'),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
      _carregarAmigos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensagem']?.toString() ?? 'Erro ao aceitar solicitação.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _recusarSolicitacao(String solicitacaoId, String nome) async {
    final res = await ApiService().responderSolicitacao(solicitacaoId, 'recusado');

    if (!mounted) return;

    if (res['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitação de $nome recusada.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      setState(() {
        _solicitacoesPendentes.removeWhere((s) => s['id']?.toString() == solicitacaoId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensagem']?.toString() ?? 'Erro ao recusar solicitação.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _removerAmigo(String amigoId, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232A),
        title: const Text('Remover Amigo', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja remover $nome da sua lista de amigos?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
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
      final res = await ApiService().removerAmigo(amigoId);
      if (!mounted) return;

      if (res['sucesso'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nome foi removido da sua lista.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        _carregarAmigos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['mensagem']?.toString() ?? 'Erro ao remover amigo.'),
            backgroundColor: Colors.redAccent,
          ),
        );
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
          'AMIGOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Color(0xFF00E676)),
            tooltip: 'Ver Classificação',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Atualizar',
            onPressed: _carregarAmigos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              icon: const Icon(Icons.people),
              text: 'Amigos (${_meusAmigos.length})',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _solicitacoesPendentes.isNotEmpty,
                label: Text('${_solicitacoesPendentes.length}'),
                backgroundColor: const Color(0xFFE91E63),
                child: const Icon(Icons.person_add_alt_1),
              ),
              text: 'Solicitações',
            ),
            Tab(
              icon: const Icon(Icons.search),
              text: 'Buscar',
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
                _buildAbaMeusAmigos(),
                _buildAbaSolicitacoes(),
                _buildAbaBuscar(),
              ],
            ),
    );
  }

  Widget _buildAbaMeusAmigos() {
    if (_meusAmigos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_erroMensagem != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _erroMensagem!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Icon(Icons.group_off_outlined, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              const Text(
                'Você ainda não possui amigos adicionados.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.search),
                label: const Text('Encontrar Amigos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: const Color(0xFF0D1117),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarAmigos,
      color: const Color(0xFF00E676),
      backgroundColor: const Color(0xFF1E232A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _meusAmigos.length,
        itemBuilder: (context, index) {
          final amigo = _meusAmigos[index];
          final nome = amigo['nome']?.toString() ?? 'Amigo';
          final letraAvatar = nome.isNotEmpty ? nome[0].toUpperCase() : 'A';
          final sequencia = (amigo['sequencia'] as num?)?.toInt() ?? 0;
          final pontos = (amigo['pontos'] as num?)?.toInt() ?? 0;
          final amigoId = amigo['id']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF8A5CF5),
                  child: Text(
                    letraAvatar,
                    style: const TextStyle(
                      color: Colors.white,
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
                      Text(
                        nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.bolt, size: 14, color: Colors.amberAccent),
                          const SizedBox(width: 2),
                          Text(
                            '$sequencia dias',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.star, size: 14, color: Color(0xFF00E676)),
                          const SizedBox(width: 2),
                          Text(
                            '$pontos pts',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                  tooltip: 'Remover Amigo',
                  onPressed: () => _removerAmigo(amigoId, nome),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAbaSolicitacoes() {
    if (_solicitacoesPendentes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarAmigos,
        color: const Color(0xFF00E676),
        backgroundColor: const Color(0xFF1E232A),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma solicitação de amizade pendente.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarAmigos,
      color: const Color(0xFF00E676),
      backgroundColor: const Color(0xFF1E232A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _solicitacoesPendentes.length,
        itemBuilder: (context, index) {
          final solic = _solicitacoesPendentes[index];
          final nome = solic['nome']?.toString() ?? 'Usuário';
          final letraAvatar = nome.isNotEmpty ? nome[0].toUpperCase() : 'U';
          final solicitacaoId = solic['id']?.toString() ?? '';
          final sequencia = (solic['sequencia'] as num?)?.toInt() ?? 0;
          final pontos = (solic['pontos'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF2196F3),
                      child: Text(
                        letraAvatar,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.bolt, size: 13, color: Colors.amberAccent),
                              Text(
                                '$sequencia dias • ',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              Text(
                                '$pontos pts',
                                style: const TextStyle(color: Color(0xFF00E676), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _recusarSolicitacao(solicitacaoId, nome),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Recusar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _aceitarSolicitacao(solicitacaoId, nome),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: const Color(0xFF0D1117),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Aceitar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAbaBuscar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _buscaController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Digite o nome do usuário...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00E676)),
              suffixIcon: _buscaController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white60),
                      onPressed: () {
                        _buscaController.clear();
                        _executarBusca('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E232A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00E676)),
              ),
            ),
            onChanged: _aoDigitarBusca,
            onSubmitted: _executarBusca,
          ),
          const SizedBox(height: 16),
          if (_buscando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          else
            Expanded(
              child: !_buscou
                  ? const Center(
                      child: Text(
                        'Busque por amigos para treinar e competir juntos!',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _resultadosBusca.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum usuário encontrado com esse nome.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _resultadosBusca.length,
                          itemBuilder: (context, index) {
                            final user = _resultadosBusca[index];
                            final nome = user['nome']?.toString() ?? 'Usuário';
                            final letraAvatar = nome.isNotEmpty ? nome[0].toUpperCase() : 'U';
                            final amigoId = user['id']?.toString() ?? '';
                            final jaAmigo = user['ja_amigo'] == true;
                            final solicitacaoEnviada = user['solicitacao_enviada'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E232A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF2D3139),
                                    child: Text(
                                      letraAvatar,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nome,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.bolt, size: 14, color: Colors.amberAccent),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${user['sequencia'] ?? 0} dias streak',
                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.star, size: 13, color: Color(0xFF00E676)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${user['pontuacao_semanal'] ?? user['pontos'] ?? 0} pts',
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
                                  if (jaAmigo)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Amigos',
                                        style: TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (solicitacaoEnviada)
                                    OutlinedButton.icon(
                                      onPressed: null,
                                      icon: const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                      label: const Text(
                                        'Enviada',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      onPressed: () => _enviarSolicitacao(amigoId, nome),
                                      icon: const Icon(Icons.person_add, size: 16),
                                      label: const Text('Conectar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00E676),
                                        foregroundColor: const Color(0xFF0D1117),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
        ],
      ),
    );
  }
}
