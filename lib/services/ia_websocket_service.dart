import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

/// Gerencia a conexão WebSocket persistente com o motor de IA no back-end.
/// Substitui o ciclo periódico de envio de imagens JPEG por streaming contínuo de ângulos leves (~200 bytes).
class IAWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  bool _conectado = false;
  bool _fechamentoManual = false;
  String? _usuarioId;
  String? _exercicioId;
  String _lado = 'direito';

  // Callbacks para o widget reagir a eventos
  final void Function(Map<String, dynamic> resultado) onResultado;
  final void Function(String status) onStatusChanged;
  final void Function(String erro) onErro;

  IAWebSocketService({
    required this.onResultado,
    required this.onStatusChanged,
    required this.onErro,
  });

  bool get conectado => _conectado;

  /// Abre a conexão WebSocket para o usuário e exercício indicados.
  Future<void> conectar({
    required String usuarioId,
    required String exercicioId,
    String lado = 'direito',
  }) async {
    _usuarioId = usuarioId;
    _exercicioId = exercicioId;
    _lado = lado;
    _fechamentoManual = false;

    await desconectar();

    final uri = Uri.parse(
      '${ApiConfig.wsBaseUrl}/ia/ws/$usuarioId?exercicio=$exercicioId&lado=$lado',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _conectado = true;
      onStatusChanged('🟢 IA Conectada (WebSocket)');

      // Inicia heartbeat preventivo a cada 20s para manter conexão viva no Render
      _iniciarPingHeartbeat();

      _subscription = _channel!.stream.listen(
        (mensagem) {
          try {
            final Map<String, dynamic> resultado =
                jsonDecode(mensagem as String) as Map<String, dynamic>;

            // Ignora resposta de heartbeat
            if (resultado['tipo'] == 'pong') {
              return;
            }

            onResultado(resultado);
          } catch (e) {
            debugPrint('Erro ao decodificar mensagem do WebSocket: $e');
          }
        },
        onError: (erro) {
          _conectado = false;
          _pingTimer?.cancel();
          onStatusChanged('🟠 Reconectando WebSocket...');
          onErro(erro.toString());
          _agendarReconexao();
        },
        onDone: () {
          _conectado = false;
          _pingTimer?.cancel();
          if (!_fechamentoManual) {
            onStatusChanged('🔴 Desconectado (Tentando reconectar...)');
            _agendarReconexao();
          } else {
            onStatusChanged('🔴 Desconectado');
          }
        },
      );
    } catch (e) {
      _conectado = false;
      _pingTimer?.cancel();
      onStatusChanged('🔴 Falha na conexão WebSocket');
      onErro(e.toString());
      _agendarReconexao();
    }
  }

  void _iniciarPingHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_conectado && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'tipo': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void _agendarReconexao() {
    if (_fechamentoManual) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (!_fechamentoManual && _usuarioId != null && _exercicioId != null) {
        conectar(
          usuarioId: _usuarioId!,
          exercicioId: _exercicioId!,
          lado: _lado,
        );
      }
    });
  }

  /// Envia ângulos calculados localmente pelo celular para processamento no servidor.
  void enviarAngulos(Map<String, double> angulos, {bool visivel = true}) {
    if (!_conectado || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'angulos': angulos,
        'visivel': visivel,
      }));
    } catch (e) {
      debugPrint('Erro ao enviar ângulos via WebSocket: $e');
    }
  }

  /// Troca de exercício dinamicamente sem necessidade de recriar o socket.
  void trocarExercicio({required String exercicioId, String lado = 'direito'}) {
    _exercicioId = exercicioId;
    _lado = lado;
    if (!_conectado || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'tipo': 'trocar_exercicio',
        'exercicio_id': exercicioId,
        'lado': lado,
      }));
    } catch (e) {
      debugPrint('Erro ao trocar exercício via WebSocket: $e');
    }
  }

  /// Solicita reinicialização da série no backend.
  void reiniciarSessao() {
    if (!_conectado || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'tipo': 'reiniciar'}));
    } catch (e) {
      debugPrint('Erro ao reiniciar sessão via WebSocket: $e');
    }
  }

  /// Encerra a conexão WebSocket e limpa listeners e timers.
  Future<void> desconectar() async {
    _fechamentoManual = true;
    _pingTimer?.cancel();
    _pingTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _conectado = false;
  }
}
