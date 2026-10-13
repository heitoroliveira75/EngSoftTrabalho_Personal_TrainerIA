import 'package:flutter/material.dart';
import '../models/exercicio_treino.dart';
import '../services/api_service.dart';

class criar_exercicio_screen extends StatefulWidget {
  const criar_exercicio_screen({super.key});

  @override
  State<criar_exercicio_screen> createState() => _CriarExercicioScreenState();
}

class _CriarExercicioScreenState extends State<criar_exercicio_screen> {
  final TextEditingController _nomeTreinoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  // ===========================================================================
  // LISTA PADRÃO DE EXERCÍCIOS (List do Dart)
  // ===========================================================================
  final List<ExercicioTreino> _exerciciosTreino = [
    ExercicioTreino(
      id: '1',
      nome: 'Supino Reto',
      grupoMuscular: 'Peitoral',
      series: 4,
      repeticoes: 10,
      pontosPorSerie: 50,
      pontosPorRepeticao: 5,
    ),
    ExercicioTreino(
      id: '2',
      nome: 'Puxada Frontal',
      grupoMuscular: 'Dorsal',
      series: 3,
      repeticoes: 12,
      pontosPorSerie: 50,
      pontosPorRepeticao: 5,
    ),
  ];

  bool _salvando = false;

  @override
  void dispose() {
    _nomeTreinoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  /// Calcula dinamicamente o total de pontos somando os pontos de cada exercício da lista
  int get _pontosTotaisTreino {
    return _exerciciosTreino.fold<int>(0, (soma, item) => soma + item.totalPontos);
  }

  /// Adiciona um novo exercício à lista
  void _adicionarExercicio(ExercicioTreino exercicio) {
    setState(() {
      _exerciciosTreino.add(exercicio);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercicio.nome} adicionado ao treino!'),
        backgroundColor: const Color(0xFF00E676),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Remove o exercício pelo índice na lista
  void _removerExercicio(int index) {
    final itemRemovido = _exerciciosTreino[index];

    setState(() {
      _exerciciosTreino.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${itemRemovido.nome} removido do treino.'),
        backgroundColor: const Color(0xFFFF5252),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Limpa todos os exercícios da lista
  void _limparTreino() {
    if (_exerciciosTreino.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232A),
        title: const Text('Limpar Treino', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Deseja remover todos os exercícios deste treino?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _exerciciosTreino.clear();
              });
            },
            child: const Text('Limpar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Salva o treino enviando a lista para a ApiService
  Future<void> _salvarTreino() async {
    final nome = _nomeTreinoController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o nome do treino.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_exerciciosTreino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione ao menos um exercício antes de salvar.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    final listaExerciciosJson =
        _exerciciosTreino.map((e) => e.toJson()).toList();

    try {
      final resposta = await ApiService().criarTreino(
        nome: nome,
        descricao: _descricaoController.text.trim(),
        exercicios: listaExerciciosJson,
      );

      if (!mounted) return;

      if (resposta['sucesso'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino "$nome" salvo com sucesso! (+$_pontosTotaisTreino pts)'),
            backgroundColor: const Color(0xFF00E676),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resposta['mensagem'] ??
                  'Treino configurado com sucesso! ($_pontosTotaisTreino pts computados).',
            ),
            backgroundColor: const Color(0xFF2196F3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino pronto localmente: $_pontosTotaisTreino pts calculados.'),
            backgroundColor: const Color(0xFF2196F3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  /// Abre o modal para configurar e adicionar um exercício com séries, reps e pontos
  void _abrirModalAdicionarExercicio() {
    final nomeCtrl = TextEditingController();
    final grupoCtrl = TextEditingController(text: 'Geral');
    int series = 3;
    int repeticoes = 10;
    int pontosPorSerie = 50;
    int pontosPorRepeticao = 5;

    // Sugestões rápidas de exercícios
    final sugestoes = [
      {'nome': 'Supino Reto', 'grupo': 'Peitoral'},
      {'nome': 'Agachamento Livre', 'grupo': 'Pernas'},
      {'nome': 'Puxada Frontal', 'grupo': 'Costas'},
      {'nome': 'Desenvolvimento', 'grupo': 'Ombros'},
      {'nome': 'Rosca Direta', 'grupo': 'Bíceps'},
      {'nome': 'Tríceps Corda', 'grupo': 'Tríceps'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E232A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final totalRepsCalculado = series * repeticoes;
            final pontosSeriesCalculado = series * pontosPorSerie;
            final pontosRepsCalculado = totalRepsCalculado * pontosPorRepeticao;
            final pontosTotalCalculado = pontosSeriesCalculado + pontosRepsCalculado;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho do Modal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Adicionar Exercício',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Chips de sugestões rápidas
                      const Text(
                        'Sugestões rápidas:',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sugestoes.map((sugestao) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                backgroundColor: const Color(0xFF2D3139),
                                label: Text(
                                  sugestao['nome']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    nomeCtrl.text = sugestao['nome']!;
                                    grupoCtrl.text = sugestao['grupo']!;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Campo de Nome
                      TextField(
                        controller: nomeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nome do Exercício',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: const Color(0xFF2D3139),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo de Grupo Muscular
                      TextField(
                        controller: grupoCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Grupo Muscular',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: const Color(0xFF2D3139),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Seletor de Séries e Repetições
                      Row(
                        children: [
                          // Séries
                          Expanded(
                            child: _buildContadorCard(
                              titulo: 'Séries',
                              valor: series,
                              onIncrementar: () => setModalState(() => series++),
                              onDecrementar: () {
                                if (series > 1) setModalState(() => series--);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Repetições por série
                          Expanded(
                            child: _buildContadorCard(
                              titulo: 'Reps/Série',
                              valor: repeticoes,
                              onIncrementar: () => setModalState(() => repeticoes++),
                              onDecrementar: () {
                                if (repeticoes > 1) setModalState(() => repeticoes--);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Card de Resumo de Pontos do Exercício
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3139),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total de Repetições:',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                                Text('$totalRepsCalculado reps',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Pontos Séries ($pontosPorSerie pts/série):',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                Text('+$pontosSeriesCalculado pts',
                                    style: const TextStyle(
                                        color: Color(0xFF64B5F6), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Pontos Repetições ($pontosPorRepeticao pts/rep):',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                Text('+$pontosRepsCalculado pts',
                                    style: const TextStyle(
                                        color: Color(0xFF64B5F6), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total deste Exercício:',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('+$pontosTotalCalculado pts',
                                    style: const TextStyle(
                                        color: Color(0xFF00E676),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Botão Confirmar Inserção
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            final nome = nomeCtrl.text.trim();
                            if (nome.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Digite o nome do exercício.'),
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              );
                              return;
                            }

                            final novoExercicio = ExercicioTreino(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              nome: nome,
                              grupoMuscular: grupoCtrl.text.trim().isEmpty
                                  ? 'Geral'
                                  : grupoCtrl.text.trim(),
                              series: series,
                              repeticoes: repeticoes,
                              pontosPorSerie: pontosPorSerie,
                              pontosPorRepeticao: pontosPorRepeticao,
                            );

                            Navigator.pop(ctx);
                            _adicionarExercicio(novoExercicio);
                          },
                          child: const Text(
                            'Adicionar ao Treino',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Construtor de card para contadores (+ / -) de séries e repetições
  Widget _buildContadorCard({
    required String titulo,
    required int valor,
    required VoidCallback onIncrementar,
    required VoidCallback onDecrementar,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3139),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 24),
                onPressed: onDecrementar,
              ),
              Text(
                '$valor',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E676), size: 24),
                onPressed: onIncrementar,
              ),
            ],
          ),
        ],
      ),
    );
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
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'TREINOS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          if (_exerciciosTreino.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Color(0xFFFF5252)),
              tooltip: 'Limpar todos os exercícios',
              onPressed: _limparTreino,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
            // 1. Campo Nome do Treino
            _buildInputField(
              controller: _nomeTreinoController,
              hintText: 'Dê um nome ao seu treino',
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: 10),

            // 2. Pontos Totais recalculados dinamicamente
            Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: 'Total de pontos: ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: '$_pontosTotaisTreino',
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' (${_exerciciosTreino.length} exercícios)',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. PARTE ESCROLÁVEL: LISTA DE EXERCÍCIOS COM LISTVIEW.BUILDER
            Expanded(
              child: _exerciciosTreino.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum exercício na lista.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Toque no botão abaixo para adicionar.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _exerciciosTreino.length,
                      itemBuilder: (context, index) {
                        final item = _exerciciosTreino[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3139),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Ícone
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    color: Color(0xFF00E676),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Detalhes do Exercício
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nome,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.grupoMuscular,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Informações de Séries, Reps e Total de Reps
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white12,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${item.series} séries × ${item.repeticoes} reps',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(${item.totalRepeticoes} totais)',
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Pontuação calculada
                                      Text(
                                        '+${item.totalPontos} pts (${item.pontosSeries} pts séries + ${item.pontosRepeticoes} pts reps)',
                                        style: const TextStyle(
                                          color: Color(0xFF64B5F6),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Botão para excluir este exercício
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFFF5252),
                                  ),
                                  tooltip: 'Excluir exercício',
                                  onPressed: () => _removerExercicio(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // BOTÕES DE AÇÃO NO RODAPÉ DA TELA
            // ==========================================

            // 1º Botão: Adicionar Exercício
            Material(
              color: const Color(0xFF2D3139),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _abrirModalAdicionarExercicio,
                child: Container(
                  width: double.infinity,
                  height: 42,
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Color(0xFF00E676), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Adicionar Exercício',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 2º Botão: Salvar Treino
            Material(
              color: const Color(0xFF2D3139),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _salvando ? null : _salvarTreino,
                child: Container(
                  width: double.infinity,
                  height: 42,
                  alignment: Alignment.center,
                  child: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2196F3),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Color(0xFF2196F3), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Salvar Treino',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
    ),
  );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF2D3139),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
