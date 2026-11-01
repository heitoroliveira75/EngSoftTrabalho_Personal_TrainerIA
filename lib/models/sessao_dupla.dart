/// Modelo de dados representativo de uma Sessão de Treino em Dupla (US-DUPLA).
/// Armazena o estado do convite, o revezamento por série e a pontuação cooperativa.
class SessaoDupla {
  final String id;
  final String hostId;
  final String convidadoId;
  final String? hostNome;
  final String? convidadoNome;
  final String? treinoId;
  final Map<String, dynamic> dadosTreino;
  final String status;
  final String? turnoUsuarioId;
  final int indiceExercicioAtual;
  final int serieAtual;
  final int totalSeries;
  final int pontosHost;
  final int pontosConvidado;
  final int pontosFinaisCada;
  final double multiplicadorAplicado;
  final String? createdAt;
  final String? updatedAt;
  final String? finalizadoEm;

  SessaoDupla({
    required this.id,
    required this.hostId,
    required this.convidadoId,
    this.hostNome,
    this.convidadoNome,
    this.treinoId,
    this.dadosTreino = const {},
    this.status = 'pendente',
    this.turnoUsuarioId,
    this.indiceExercicioAtual = 0,
    this.serieAtual = 1,
    this.totalSeries = 3,
    this.pontosHost = 0,
    this.pontosConvidado = 0,
    this.pontosFinaisCada = 0,
    this.multiplicadorAplicado = 1.20,
    this.createdAt,
    this.updatedAt,
    this.finalizadoEm,
  });

  bool get isPendente => status == 'pendente';
  bool get isAceito => status == 'aceito';
  bool get isEmAndamento => status == 'em_andamento';
  bool get isFinalizado => status == 'finalizado';
  bool get isRecusado => status == 'recusado';
  bool get isCancelado => status == 'cancelado';

  bool isMeuTurno(String? meuId) =>
      meuId != null && turnoUsuarioId != null && meuId == turnoUsuarioId;

  String idParceiro(String? meuId) =>
      meuId == hostId ? convidadoId : hostId;

  String nomeParceiro(String? meuId) =>
      meuId == hostId ? (convidadoNome ?? 'Parceiro') : (hostNome ?? 'Host');

  factory SessaoDupla.fromJson(Map<String, dynamic> json) {
    return SessaoDupla(
      id: (json['id'] ?? json['sessao_id'] ?? '').toString(),
      hostId: (json['host_id'] ?? '').toString(),
      convidadoId: (json['convidado_id'] ?? '').toString(),
      hostNome: json['host_nome']?.toString(),
      convidadoNome: json['convidado_nome']?.toString(),
      treinoId: json['treino_id']?.toString(),
      dadosTreino: json['dados_treino'] is Map
          ? Map<String, dynamic>.from(json['dados_treino'] as Map)
          : {},
      status: (json['status'] ?? 'pendente').toString(),
      turnoUsuarioId: json['turno_usuario_id']?.toString(),
      indiceExercicioAtual: (json['indice_exercicio_atual'] as num?)?.toInt() ?? 0,
      serieAtual: (json['serie_atual'] as num?)?.toInt() ?? 1,
      totalSeries: (json['total_series'] as num?)?.toInt() ?? 3,
      pontosHost: (json['pontos_host'] as num?)?.toInt() ?? 0,
      pontosConvidado: (json['pontos_convidado'] as num?)?.toInt() ?? 0,
      pontosFinaisCada: (json['pontos_finais_cada'] as num?)?.toInt() ?? 0,
      multiplicadorAplicado: (json['multiplicador_aplicado'] as num?)?.toDouble() ?? 1.20,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      finalizadoEm: json['finalizado_em']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'convidado_id': convidadoId,
      'host_nome': hostNome,
      'convidado_nome': convidadoNome,
      'treino_id': treinoId,
      'dados_treino': dadosTreino,
      'status': status,
      'turno_usuario_id': turnoUsuarioId,
      'indice_exercicio_atual': indiceExercicioAtual,
      'serie_atual': serieAtual,
      'total_series': totalSeries,
      'pontos_host': pontosHost,
      'pontos_convidado': pontosConvidado,
      'pontos_finais_cada': pontosFinaisCada,
      'multiplicador_aplicado': multiplicadorAplicado,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'finalizado_em': finalizadoEm,
    };
  }
}
