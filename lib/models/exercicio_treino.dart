/// Modelo de dados padrão para um exercício dentro de um treino.
/// Contém dados do exercício, séries, repetições por série, cálculo de total de repetições
/// e pontuações calculadas.
class ExercicioTreino {
  final String id;
  String nome;
  String grupoMuscular;
  int series;
  int repeticoes;
  int pontosPorSerie;
  int pontosPorRepeticao;

  ExercicioTreino({
    required this.id,
    required this.nome,
    this.grupoMuscular = 'Geral',
    this.series = 3,
    this.repeticoes = 10,
    this.pontosPorSerie = 50,
    this.pontosPorRepeticao = 5,
  });

  /// Total de repetições realizadas: séries × repetições por série
  int get totalRepeticoes => series * repeticoes;

  /// Pontos calculados das séries
  int get pontosSeries => series * pontosPorSerie;

  /// Pontos calculados das repetições
  int get pontosRepeticoes => totalRepeticoes * pontosPorRepeticao;

  /// Pontos totais deste exercício (séries + repetições)
  int get totalPontos => pontosSeries + pontosRepeticoes;

  /// Converte para Map/JSON para envio à API ou armazenamento local
  Map<String, dynamic> toJson() {
    return {
      'exercicio_id': id,
      'nome': nome,
      'grupo_muscular': grupoMuscular,
      'series': series,
      'repeticoes': repeticoes,
      'total_repeticoes': totalRepeticoes,
      'pontos_series': pontosSeries,
      'pontos_repeticoes': pontosRepeticoes,
      'pontos_totais': totalPontos,
    };
  }

  factory ExercicioTreino.fromJson(Map<String, dynamic> json) {
    return ExercicioTreino(
      id: json['exercicio_id']?.toString() ?? json['id']?.toString() ?? '',
      nome: json['nome'] ?? 'Exercício',
      grupoMuscular: json['grupo_muscular'] ?? 'Geral',
      series: json['series'] is int
          ? json['series']
          : int.tryParse(json['series']?.toString() ?? '3') ?? 3,
      repeticoes: json['repeticoes'] is int
          ? json['repeticoes']
          : int.tryParse(json['repeticoes']?.toString() ?? '10') ?? 10,
      pontosPorSerie: json['pontos_por_serie'] is int
          ? json['pontos_por_serie']
          : int.tryParse(json['pontos_por_serie']?.toString() ?? '50') ?? 50,
      pontosPorRepeticao: json['pontos_por_repeticao'] is int
          ? json['pontos_por_repeticao']
          : int.tryParse(json['pontos_por_repeticao']?.toString() ?? '5') ?? 5,
    );
  }
}
