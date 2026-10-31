import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'treino_selecionado_screen.dart';
import 'criar_exercicio_screen.dart';

// MOCK EXPANDIDO DE DADOS POR DIFICULDADE (FALLBACK OFFLINE)
final Map<String, List<Map<String, dynamic>>> bancoDeTreinos = {
  'iniciante': [
    {
      'id': '1',
      'titulo': 'Corpo completo A',
      'dificuldade': 'Iniciante',
      'exerciciosCount': 8,
      'duracaoMinutos': 40,
      'pontosTotais': 200,
      'corTema': const Color(0xFF00E676),
      'exercicios': [
        {'nome': 'Polichinelo', 'series': 3, 'repeticoes': 12, 'pontos': 20},
        {
          'nome': 'Agachamento Livre',
          'series': 3,
          'repeticoes': 12,
          'pontos': 20,
        },
        {
          'nome': 'Flexão com Joelhos',
          'series': 3,
          'repeticoes': 10,
          'pontos': 20,
        },
        {
          'nome': 'Abdominal Supra',
          'series': 3,
          'repeticoes': 15,
          'pontos': 20,
        },
        {
          'nome': 'Prancha Abdominal',
          'series': 3,
          'repeticoes': 30,
          'pontos': 20,
        },
        {
          'nome': 'Elevação Pélvica',
          'series': 3,
          'repeticoes': 12,
          'pontos': 20,
        },
        {'nome': 'Passada Parada', 'series': 3, 'repeticoes': 10, 'pontos': 20},
        {
          'nome': 'Polichinelo Inverso',
          'series': 3,
          'repeticoes': 12,
          'pontos': 20,
        },
      ],
    },
    {
      'id': '2',
      'titulo': 'Membros Inferiores & Core',
      'dificuldade': 'Iniciante',
      'exerciciosCount': 5,
      'duracaoMinutos': 25,
      'pontosTotais': 140,
      'corTema': const Color(0xFF00E676),
      'exercicios': [
        {
          'nome': 'Agachamento Isométrico',
          'series': 3,
          'repeticoes': 30,
          'pontos': 25,
        },
        {
          'nome': 'Afundo Alternado',
          'series': 3,
          'repeticoes': 10,
          'pontos': 25,
        },
        {
          'nome': 'Abdominal Infra',
          'series': 3,
          'repeticoes': 12,
          'pontos': 30,
        },
        {'nome': 'Ponte Glúteos', 'series': 3, 'repeticoes': 15, 'pontos': 30},
        {
          'nome': 'Elevação de Panturrilha',
          'series': 3,
          'repeticoes': 20,
          'pontos': 30,
        },
      ],
    },
    {
      'id': '3',
      'titulo': 'Mobilidade e Alongamento',
      'dificuldade': 'Iniciante',
      'exerciciosCount': 6,
      'duracaoMinutos': 20,
      'pontosTotais': 100,
      'corTema': const Color(0xFF00E676),
      'exercicios': [
        {
          'nome': 'Rotação de Tronco',
          'series': 2,
          'repeticoes': 15,
          'pontos': 15,
        },
        {'nome': 'Gato-Camelo', 'series': 3, 'repeticoes': 10, 'pontos': 15},
        {
          'nome': 'Alongamento de Posteriores',
          'series': 2,
          'repeticoes': 30,
          'pontos': 20,
        },
        {
          'nome': 'Alongamento de Quadríceps',
          'series': 2,
          'repeticoes': 30,
          'pontos': 20,
        },
        {
          'nome': 'Rotação de Ombros',
          'series': 2,
          'repeticoes': 12,
          'pontos': 15,
        },
        {
          'nome': 'Postura da Criança',
          'series': 2,
          'repeticoes': 45,
          'pontos': 15,
        },
      ],
    },
  ],
  'intermediario': [
    {
      'id': '4',
      'titulo': 'Superiores & HIIT',
      'dificuldade': 'Intermediário',
      'exerciciosCount': 7,
      'duracaoMinutos': 45,
      'pontosTotais': 280,
      'corTema': const Color(0xFF29B6F6),
      'exercicios': [
        {
          'nome': 'Flexão Tradicional',
          'series': 4,
          'repeticoes': 12,
          'pontos': 35,
        },
        {
          'nome': 'Tríceps no Banco',
          'series': 4,
          'repeticoes': 12,
          'pontos': 35,
        },
        {
          'nome': 'Mountain Climber',
          'series': 4,
          'repeticoes': 20,
          'pontos': 40,
        },
        {
          'nome': 'Desenvolvimento Halteres',
          'series': 4,
          'repeticoes': 10,
          'pontos': 40,
        },
        {'nome': 'Remada Curvada', 'series': 4, 'repeticoes': 12, 'pontos': 40},
        {
          'nome': 'Abdominal Remador',
          'series': 4,
          'repeticoes': 15,
          'pontos': 45,
        },
        {
          'nome': 'Prancha Dinâmica',
          'series': 3,
          'repeticoes': 40,
          'pontos': 45,
        },
      ],
    },
    {
      'id': '5',
      'titulo': 'Pernas & Glúteos Intenso',
      'dificuldade': 'Intermediário',
      'exerciciosCount': 6,
      'duracaoMinutos': 35,
      'pontosTotais': 250,
      'corTema': const Color(0xFF29B6F6),
      'exercicios': [
        {
          'nome': 'Agachamento Búlgaro',
          'series': 3,
          'repeticoes': 10,
          'pontos': 40,
        },
        {
          'nome': 'Agachamento Sumô',
          'series': 4,
          'repeticoes': 12,
          'pontos': 40,
        },
        {
          'nome': 'Stiff com Halteres',
          'series': 4,
          'repeticoes': 12,
          'pontos': 40,
        },
        {
          'nome': 'Saltos Vertical na Caixa',
          'series': 3,
          'repeticoes': 10,
          'pontos': 40,
        },
        {
          'nome': 'Elevação Pélvica Unilateral',
          'series': 3,
          'repeticoes': 12,
          'pontos': 45,
        },
        {
          'nome': 'Cadeira Flexora',
          'series': 3,
          'repeticoes': 15,
          'pontos': 45,
        },
      ],
    },
    {
      'id': '6',
      'titulo': 'Desafio Core & Cardio',
      'dificuldade': 'Intermediário',
      'exerciciosCount': 5,
      'duracaoMinutos': 30,
      'pontosTotais': 220,
      'corTema': const Color(0xFF29B6F6),
      'exercicios': [
        {'nome': 'Russian Twist', 'series': 4, 'repeticoes': 20, 'pontos': 40},
        {
          'nome': 'Prancha Lateral com Elevação',
          'series': 3,
          'repeticoes': 10,
          'pontos': 45,
        },
        {
          'nome': 'Polichinelo com Carga',
          'series': 4,
          'repeticoes': 20,
          'pontos': 45,
        },
        {
          'nome': 'Bicicleta Abdominal',
          'series': 4,
          'repeticoes': 20,
          'pontos': 45,
        },
        {
          'nome': 'Corrida Estacionária',
          'series': 4,
          'repeticoes': 45,
          'pontos': 45,
        },
      ],
    },
  ],
  'avancado': [
    {
      'id': '7',
      'titulo': 'Full Body Extreme',
      'dificuldade': 'Avançado',
      'exerciciosCount': 8,
      'duracaoMinutos': 55,
      'pontosTotais': 480,
      'corTema': const Color(0xFF9E7AFF),
      'exercicios': [
        {
          'nome': 'Burpee Completo com Flexão',
          'series': 4,
          'repeticoes': 15,
          'pontos': 60,
        },
        {
          'nome': 'Agachamento com Salto',
          'series': 4,
          'repeticoes': 20,
          'pontos': 60,
        },
        {
          'nome': 'Flexão Declinada',
          'series': 4,
          'repeticoes': 15,
          'pontos': 60,
        },
        {
          'nome': 'Pistol Squat (Cada Perna)',
          'series': 3,
          'repeticoes': 8,
          'pontos': 60,
        },
        {
          'nome': 'Barra Fixa Pronada',
          'series': 4,
          'repeticoes': 10,
          'pontos': 60,
        },
        {
          'nome': 'Abdominal Canivete',
          'series': 4,
          'repeticoes': 15,
          'pontos': 60,
        },
        {
          'nome': 'Prancha com Carga',
          'series': 4,
          'repeticoes': 60,
          'pontos': 60,
        },
        {'nome': 'Sprawl Cardio', 'series': 4, 'repeticoes': 15, 'pontos': 60},
      ],
    },
    {
      'id': '8',
      'titulo': 'Calistenia de Alta Performance',
      'dificuldade': 'Avançado',
      'exerciciosCount': 6,
      'duracaoMinutos': 50,
      'pontosTotais': 400,
      'corTema': const Color(0xFF9E7AFF),
      'exercicios': [
        {
          'nome': 'Flexão Diamante',
          'series': 4,
          'repeticoes': 15,
          'pontos': 65,
        },
        {
          'nome': 'Muscle Up / Flexão na Barra',
          'series': 4,
          'repeticoes': 6,
          'pontos': 70,
        },
        {
          'nome': 'Flexão Pseudo-Planoche',
          'series': 4,
          'repeticoes': 10,
          'pontos': 65,
        },
        {
          'nome': 'Agachamento Búlgaro Salto',
          'series': 4,
          'repeticoes': 12,
          'pontos': 65,
        },
        {
          'nome': 'L-Sit na Paralela',
          'series': 4,
          'repeticoes': 20,
          'pontos': 70,
        },
        {
          'nome': 'Dragon Flag Flexion',
          'series': 3,
          'repeticoes': 8,
          'pontos': 65,
        },
      ],
    },
  ],
  'meus_treinos': [
    {
      'id': 'm1',
      'titulo': 'Corpo completo',
      'dificuldade': 'Personalizado',
      'exerciciosCount': 4,
      'duracaoMinutos': 20,
      'pontosTotais': 160,
      'corTema': const Color(0xFF29B6F6),
      'exercicios': [
        {'nome': 'Polichinelo', 'series': 3, 'repeticoes': 12, 'pontos': 20},
        {'nome': 'Agachamento Livre', 'series': 3, 'repeticoes': 12, 'pontos': 20},
        {'nome': 'Flexão de Braço', 'series': 3, 'repeticoes': 10, 'pontos': 20},
        {'nome': 'Prancha Abdominal', 'series': 3, 'repeticoes': 30, 'pontos': 20},
      ],
    },
  ],
};

class OpcaoTreinosScreen extends StatefulWidget {
  final String dificuldadeFlag;

  const OpcaoTreinosScreen({super.key, required this.dificuldadeFlag});

  @override
  State<OpcaoTreinosScreen> createState() => _OpcaoTreinosScreenState();
}

class _OpcaoTreinosScreenState extends State<OpcaoTreinosScreen> {
  bool _carregando = true;
  List<Map<String, dynamic>> _listaTreinos = [];

  Color get _corTema {
    switch (widget.dificuldadeFlag) {
      case 'iniciante':
        return const Color(0xFF00E676);
      case 'intermediario':
        return const Color(0xFF29B6F6);
      case 'avancado':
        return const Color(0xFF9E7AFF);
      case 'meus_treinos':
        return const Color(0xFF29B6F6);
      default:
        return const Color(0xFF00E676);
    }
  }

  String get _tituloDificuldade {
    switch (widget.dificuldadeFlag) {
      case 'iniciante':
        return 'INICIANTE';
      case 'intermediario':
        return 'INTERMEDIÁRIO';
      case 'avancado':
        return 'AVANÇADO';
      case 'meus_treinos':
        return 'MEUS TREINOS';
      default:
        return 'TREINOS';
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  /// Retorna um mapa { titulo_em_minusculo : id_do_treino_salvo }
  Future<Map<String, String>> _obterTreinosSalvosUsuario() async {
    final Map<String, String> salvosPorTitulo = {};
    try {
      final idUsuario = ApiService().idUsuarioAtual;
      final res = await ApiService().listarTreinosUsuario(idUsuario);
      if (res['sucesso'] == true && res['treinos'] is List) {
        for (final t in (res['treinos'] as List)) {
          if (t is Map) {
            final titulo = (t['nome'] ?? t['titulo'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            final id = t['id']?.toString() ?? '';
            if (titulo.isNotEmpty && id.isNotEmpty) {
              salvosPorTitulo[titulo] = id;
            }
          }
        }
      }
    } catch (_) {}
    return salvosPorTitulo;
  }

  Future<void> _alternarSalvarTreinoCard(Map<String, dynamic> treino) async {
    if (treino['salvando'] == true) return;

    final bool novoStatus = !(treino['salvo'] == true);
    setState(() {
      treino['salvo'] = novoStatus;
      treino['salvando'] = true;
    });

    if (novoStatus) {
      final idUsuario = ApiService().idUsuarioAtual;
      final exercicios = (treino['exercicios'] as List? ?? [])
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
          nome: treino['titulo'] ?? 'Treino',
          descricao:
              'Treino salvo dos treinos ${treino['dificuldade'] ?? 'padrões'}',
          dificuldade: treino['dificuldade']?.toString() ?? 'Personalizado',
          duracaoMinutos: (treino['duracaoMinutos'] as num?)?.toInt() ?? 30,
          pontosTotais: (treino['pontosTotais'] as num?)?.toInt() ?? 100,
          exercicios: exercicios,
        );

        final novoId =
            res['treino']?['id']?.toString() ?? res['id']?.toString();
        if (novoId != null && novoId.isNotEmpty) {
          treino['idSalvo'] = novoId;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['sucesso'] == true
                    ? 'Treino salvo nos Meus Treinos com sucesso!'
                    : (res['mensagem'] ?? 'Treino salvo localmente.'),
              ),
              backgroundColor: res['sucesso'] == true
                  ? const Color(0xFF00E676)
                  : Colors.blueGrey,
              duration: const Duration(seconds: 2),
            ),
          );
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
        if (mounted) {
          setState(() => treino['salvando'] = false);
        }
      }
    } else {
      try {
        String? idParaExcluir = treino['idSalvo']?.toString();

        if (idParaExcluir == null || idParaExcluir.isEmpty) {
          final idUsuario = ApiService().idUsuarioAtual;
          final resLista = await ApiService().listarTreinosUsuario(idUsuario);
          final tituloAlvo =
              (treino['titulo'] ?? '').toString().trim().toLowerCase();

          if (resLista['sucesso'] == true && resLista['treinos'] is List) {
            for (final t in (resLista['treinos'] as List)) {
              if (t is Map) {
                final nome = (t['nome'] ?? t['titulo'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();
                if (nome == tituloAlvo && t['id'] != null) {
                  idParaExcluir = t['id'].toString();
                  break;
                }
              }
            }
          }
        }

        if (idParaExcluir != null && idParaExcluir.isNotEmpty) {
          await ApiService().excluirTreino(idParaExcluir);
          treino['idSalvo'] = null;
        }
      } catch (_) {
      } finally {
        if (mounted) {
          setState(() {
            treino['salvando'] = false;
            if (widget.dificuldadeFlag == 'meus_treinos') {
              _listaTreinos.remove(treino);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino removido dos salvos.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _carregarTreinos() async {
    setState(() => _carregando = true);

    Map<String, String> salvosPorTitulo = {};

    try {
      if (widget.dificuldadeFlag == 'meus_treinos') {
        final idUsuario = ApiService().idUsuarioAtual;
        final res = await ApiService().listarTreinosUsuario(idUsuario);

        if (!mounted) return;

        if (res['sucesso'] == true &&
            res['treinos'] is List &&
            (res['treinos'] as List).isNotEmpty) {
          final List treinosRaw = res['treinos'];
          final List<Map<String, dynamic>> convertidos = [];

          for (final t in treinosRaw) {
            final List<Map<String, dynamic>> exerciciosMapeados = [];

            // 1. Tenta extrair diretamente de t['exercicios']
            if (t['exercicios'] is List && (t['exercicios'] as List).isNotEmpty) {
              for (final ex in t['exercicios']) {
                if (ex is Map) {
                  final series = ex['series'] ?? 3;
                  final reps = ex['repeticoes'] ?? 10;
                  final pontos = ex['pontos'] ?? ex['pontos_totais'] ?? ((series is int) ? series * 15 : 45);
                  exerciciosMapeados.add({
                    'id': ex['id']?.toString() ?? ex['exercicio_id']?.toString() ?? '1',
                    'nome': ex['nome']?.toString() ?? 'Exercício',
                    'series': series,
                    'repeticoes': reps,
                    'pontos': pontos,
                    'pontos_totais': pontos,
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
                  final series = te['series'] ?? 3;
                  final reps = te['repeticoes'] ?? 10;
                  final pontos = (series is int) ? series * 15 : 45;
                  exerciciosMapeados.add({
                    'id': te['exercicio_id']?.toString() ?? te['id']?.toString() ?? '1',
                    'nome': nomeEx.toString(),
                    'series': series,
                    'repeticoes': reps,
                    'pontos': pontos,
                    'pontos_totais': pontos,
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
                      final series = ex['series'] ?? 3;
                      final reps = ex['repeticoes'] ?? 10;
                      final pontos = ex['pontos'] ?? ex['pontos_totais'] ?? ((series is int) ? series * 15 : 45);
                      exerciciosMapeados.add({
                        'id': ex['id']?.toString() ?? ex['exercicio_id']?.toString() ?? '1',
                        'nome': ex['nome']?.toString() ?? 'Exercício',
                        'series': series,
                        'repeticoes': reps,
                        'pontos': pontos,
                        'pontos_totais': pontos,
                      });
                    }
                  }
                }
              } catch (_) {}
            }

            final totalPontos = exerciciosMapeados.fold<int>(
              0,
              (soma, item) => soma + ((item['pontos'] as num?)?.toInt() ?? 0),
            );

            final duracao = (t['duracaoMinutos'] as num?)?.toInt() ??
                (t['duracao_minutos'] as num?)?.toInt() ??
                (exerciciosMapeados.isEmpty ? 20 : exerciciosMapeados.length * 5);

            final pontosTreino = (t['pontosTotais'] as num?)?.toInt() ??
                (t['pontos_totais'] as num?)?.toInt() ??
                (totalPontos > 0 ? totalPontos : 150);

            final String idBanco = t['id'].toString();
            convertidos.add({
              'id': idBanco,
              'idSalvo': idBanco,
              'titulo': t['nome'] ?? t['titulo'] ?? 'Treino Personalizado',
              'dificuldade': t['dificuldade'] ?? 'Personalizado',
              'exerciciosCount': exerciciosMapeados.length,
              'duracaoMinutos': duracao,
              'pontosTotais': pontosTreino,
              'corTema': const Color(0xFF29B6F6),
              'exercicios': exerciciosMapeados,
              'salvo': true,
            });
          }

          setState(() {
            _listaTreinos = convertidos;
            _carregando = false;
          });
          return;
        } else {
          // Se a lista da API for vazia, usa os treinos locais padrão de meus_treinos
          setState(() {
            _listaTreinos = (bancoDeTreinos['meus_treinos'] ?? [])
                .map((t) => {...t, 'salvo': true, 'idSalvo': t['id']?.toString()})
                .toList();
            _carregando = false;
          });
          return;
        }
      } else {
        // Busca os treinos salvos do usuário (nome -> id) e os treinos da dificuldade
        salvosPorTitulo = await _obterTreinosSalvosUsuario();

        final res = await ApiService()
            .obterTreinosPorDificuldade(widget.dificuldadeFlag);

        if (!mounted) return;

        if (res['sucesso'] == true &&
            res['treinos'] is List &&
            (res['treinos'] as List).isNotEmpty) {
          final List raw = res['treinos'];
          final List<Map<String, dynamic>> list = [];

          for (final item in raw) {
            Color cor = _corTema;
            if (item['corTema'] is String) {
              final hex = (item['corTema'] as String).replaceAll('#', '');
              if (hex.length == 6) {
                cor = Color(int.parse('0xFF$hex'));
              }
            }

            final String tituloTreino = item['titulo'] ?? 'Treino';
            final String chaveTitulo = tituloTreino.trim().toLowerCase();
            final String? idSalvo = salvosPorTitulo[chaveTitulo];

            list.add({
              'id': item['id']?.toString() ?? '',
              'idSalvo': idSalvo,
              'titulo': tituloTreino,
              'dificuldade': item['dificuldade'] ?? _tituloDificuldade,
              'exerciciosCount': item['exerciciosCount'] ??
                  (item['exercicios'] as List?)?.length ??
                  0,
              'duracaoMinutos': item['duracaoMinutos'] ?? 30,
              'pontosTotais': item['pontosTotais'] ?? 200,
              'corTema': cor,
              'exercicios': item['exercicios'] ?? [],
              'salvo': idSalvo != null,
            });
          }

          setState(() {
            _listaTreinos = list;
            _carregando = false;
          });
          return;
        }
      }
    } catch (_) {
      // Em caso de falha de conexão, fallback seguro para os dados locais
    }

    if (!mounted) return;

    setState(() {
      _listaTreinos = (bancoDeTreinos[widget.dificuldadeFlag] ?? []).map((t) {
        final String chaveTitulo =
            (t['titulo'] ?? '').toString().trim().toLowerCase();
        final String? idSalvo = widget.dificuldadeFlag == 'meus_treinos'
            ? t['id']?.toString()
            : salvosPorTitulo[chaveTitulo];
        final bool jaSalvo =
            widget.dificuldadeFlag == 'meus_treinos' || idSalvo != null;
        return {
          ...t,
          'idSalvo': idSalvo,
          'salvo': jaSalvo,
        };
      }).toList();
      _carregando = false;
    });
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
          'TREINO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _carregarTreinos,
          ),
          if (widget.dificuldadeFlag == 'meus_treinos')
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF00E676)),
              tooltip: 'Criar Treino',
              onPressed: () async {
                final criado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CriarExercicioScreen(),
                  ),
                );
                if (criado == true) {
                  _carregarTreinos();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text(
              _tituloDificuldade,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _carregando
                ? Center(
                    child: CircularProgressIndicator(color: _corTema),
                  )
                : _listaTreinos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.fitness_center_outlined,
                              size: 48,
                              color: Colors.white38,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Você ainda não possui treinos salvos.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                final criado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CriarExercicioScreen(),
                                  ),
                                );
                                if (criado == true) {
                                  _carregarTreinos();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Criar Meu Primeiro Treino'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarTreinos,
                        color: _corTema,
                        backgroundColor: const Color(0xFF1E232A),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          itemCount: _listaTreinos.length,
                          itemBuilder: (context, index) {
                            final treino = _listaTreinos[index];
                            final Color corCard =
                                treino['corTema'] ?? _corTema;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: InkWell(
                                onTap: () async {
                                  final concluido = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TreinoSelecionadoScreen(
                                              treinoData: treino),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (widget.dificuldadeFlag == 'meus_treinos' &&
                                      (concluido == true ||
                                          treino['salvo'] == false)) {
                                    _carregarTreinos();
                                  } else {
                                    setState(() {});
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161B22),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: corCard, width: 1.8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              treino['titulo'] ?? 'Treino',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            visualDensity:
                                                VisualDensity.compact,
                                            tooltip: treino['salvo'] == true
                                                ? 'Remover dos Meus Treinos'
                                                : 'Salvar nos Meus Treinos',
                                            onPressed:
                                                treino['salvando'] == true
                                                    ? null
                                                    : () =>
                                                        _alternarSalvarTreinoCard(
                                                            treino),
                                            icon: treino['salvando'] == true
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.amber,
                                                    ),
                                                  )
                                                : Icon(
                                                    treino['salvo'] == true
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color:
                                                        treino['salvo'] == true
                                                            ? Colors.amber
                                                            : Colors.grey,
                                                    size: 26,
                                                  ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${treino['exerciciosCount'] ?? 0} exercícios, ${treino['duracaoMinutos'] ?? 30} minutos',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(
                                          color: Colors.grey, height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '+${treino['pontosTotais'] ?? 100} pts',
                                            style: TextStyle(
                                              color: corCard,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            treino['dificuldade'] ?? 'Geral',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
