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

  // Catálogo de exercícios pré-definidos organizados por grupo muscular
  static const Map<String, List<Map<String, dynamic>>> _catalogoExercicios = {
    'Peitoral': [
      {'id': '1', 'nome': 'Supino Reto', 'pontosSerie': 50, 'pontosRep': 5},
      {'id': '2', 'nome': 'Supino Inclinado', 'pontosSerie': 50, 'pontosRep': 5},
      {'id': '3', 'nome': 'Crucifixo Reto', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '4', 'nome': 'Crossover na Polia', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '5', 'nome': 'Flexão de Braço', 'pontosSerie': 40, 'pontosRep': 4},
    ],
    'Costas': [
      {'id': '6', 'nome': 'Puxada Frontal', 'pontosSerie': 50, 'pontosRep': 5},
      {'id': '7', 'nome': 'Remada Baixa', 'pontosSerie': 50, 'pontosRep': 5},
      {'id': '8', 'nome': 'Remada Curvada', 'pontosSerie': 55, 'pontosRep': 5},
      {'id': '9', 'nome': 'Barra Fixa', 'pontosSerie': 60, 'pontosRep': 6},
      {'id': '10', 'nome': 'Pulldown', 'pontosSerie': 45, 'pontosRep': 4},
    ],
    'Pernas': [
      {'id': '11', 'nome': 'Agachamento Livre', 'pontosSerie': 60, 'pontosRep': 6},
      {'id': '12', 'nome': 'Leg Press 45°', 'pontosSerie': 55, 'pontosRep': 5},
      {'id': '13', 'nome': 'Cadeira Extensora', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '14', 'nome': 'Mesa Flexora', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '15', 'nome': 'Panturrilha em Pé', 'pontosSerie': 40, 'pontosRep': 4},
    ],
    'Ombros': [
      {'id': '16', 'nome': 'Desenvolvimento com Halteres', 'pontosSerie': 50, 'pontosRep': 5},
      {'id': '17', 'nome': 'Elevação Lateral', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '18', 'nome': 'Elevação Frontal', 'pontosSerie': 40, 'pontosRep': 4},
      {'id': '19', 'nome': 'Crucifixo Invertido', 'pontosSerie': 45, 'pontosRep': 4},
    ],
    'Bíceps': [
      {'id': '20', 'nome': 'Rosca Direta', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '21', 'nome': 'Rosca Alternada', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '22', 'nome': 'Rosca Martelo', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '23', 'nome': 'Rosca Scott', 'pontosSerie': 50, 'pontosRep': 5},
    ],
    'Tríceps': [
      {'id': '24', 'nome': 'Tríceps Corda', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '25', 'nome': 'Tríceps Pulley', 'pontosSerie': 45, 'pontosRep': 4},
      {'id': '26', 'nome': 'Tríceps Testa', 'pontosSerie': 50, 'pontosRep': 5},
      {'id': '27', 'nome': 'Mergulho no Banco', 'pontosSerie': 40, 'pontosRep': 4},
    ],
    'Abdômen': [
      {'id': '28', 'nome': 'Abdominal Supra', 'pontosSerie': 40, 'pontosRep': 3},
      {'id': '29', 'nome': 'Prancha Abdominal', 'pontosSerie': 50, 'pontosRep': 5},
      {'id': '30', 'nome': 'Elevação de Pernas', 'pontosSerie': 45, 'pontosRep': 4},
    ],
  };

  // Lista inicial de exercicios
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
      id: '6',
      nome: 'Puxada Frontal',
      grupoMuscular: 'Costas',
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
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    if (_exerciciosTreino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione ao menos um exercício antes de salvar.'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    final listaExerciciosJson =
        _exerciciosTreino.map((exercicio) => exercicio.toJson()).toList();

    try {
      final resposta = await ApiService().criarTreino(
        nome: nome,
        descricao: '',
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
              resposta['mensagem'] ?? 'Erro ao salvar treino no servidor.',
            ),
            backgroundColor: const Color(0xFF8B0000),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha de conexão: não foi possível salvar o treino no servidor.'),
            backgroundColor: Color(0xFF8B0000),
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
    final grupos = _catalogoExercicios.keys.toList();
    String grupoSelecionado = grupos.first;
    Map<String, dynamic> exercicioSelecionado = _catalogoExercicios[grupoSelecionado]!.first;

    int series = 3;
    int repeticoes = 10;

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
            final pontosPorSerie = (exercicioSelecionado['pontosSerie'] as int?) ?? 50;
            final pontosPorRepeticao = (exercicioSelecionado['pontosRep'] as int?) ?? 5;
            final totalRepsCalculado = series * repeticoes;
            final pontosSeriesCalculado = series * pontosPorSerie;
            final pontosRepsCalculado = totalRepsCalculado * pontosPorRepeticao;
            final pontosTotalCalculado = pontosSeriesCalculado + pontosRepsCalculado;

            final exerciciosDoGrupo = _catalogoExercicios[grupoSelecionado]!;

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

                      const SizedBox(height: 16),

                      // Texto
                      const Text(
                        '1. Grupo Muscular',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Grupos para selecionar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: grupos.map((grupo) {
                            final selecionado = grupo == grupoSelecionado;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  grupo,
                                  style: TextStyle(
                                    color: selecionado ? Colors.black : Colors.white70,
                                    fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: selecionado,
                                selectedColor: const Color(0xFF00E676),
                                backgroundColor: const Color(0xFF2D3139),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: selecionado ? const Color(0xFF00E676) : Colors.transparent,
                                  ),
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(() {
                                      grupoSelecionado = grupo;
                                      exercicioSelecionado = _catalogoExercicios[grupo]!.first;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Texto
                      const Text(
                        '2. Exercício Pré-definido',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Seleção de exercicio
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3139),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: exercicioSelecionado['id'].toString(),
                            dropdownColor: const Color(0xFF252830),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E676)),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            items: exerciciosDoGrupo.map((item) {
                              return DropdownMenuItem<String>(
                                value: item['id'].toString(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['nome'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '+${item['pontosSerie']} pts/série',
                                      style: const TextStyle(
                                        color: Color(0xFF64B5F6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (novoId) {
                              if (novoId != null) {
                                setModalState(() {
                                  exercicioSelecionado = exerciciosDoGrupo.firstWhere(
                                    (item) => item['id'].toString() == novoId,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Series e repetições
                      Row(
                        children: [
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

                      // Resumo
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

                      // Botão de adicionar
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
                            final novoExercicio = ExercicioTreino(
                              id: exercicioSelecionado['id'].toString(),
                              nome: exercicioSelecionado['nome'] as String,
                              grupoMuscular: grupoSelecionado,
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

      // Botão de voltar canto superior
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

      // Corpo da tela
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
              //se vacio mostrar que n tem exercicio
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
                  //se não estiver vazio mostra a lista
                  : ListView.builder(
                      itemCount: _exerciciosTreino.length,
                      itemBuilder: (context, index) {
                        final item = _exerciciosTreino[index];

                        // Montagem lista de exercicios
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

            // Botões no roda pé

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

}
