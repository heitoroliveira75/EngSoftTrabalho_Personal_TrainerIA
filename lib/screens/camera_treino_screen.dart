import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../services/api_service.dart';
import '../services/pose_service.dart';
import '../services/ia_websocket_service.dart';

class CameraTreinoScreen extends StatefulWidget {
  final CameraDescription? camera;
  final String? endpoint;
  final String exercicioId;
  final String exercicioNome;
  final int metaRepeticoes;
  final int exercicioIndice;
  final int totalExercicios;
  final String? proximoExercicioNome;
  final List<Map<String, dynamic>>? listaExercicios;
  final int indiceInicial;

  const CameraTreinoScreen({
    super.key,
    this.camera,
    this.endpoint,
    this.exercicioId = '16',
    this.exercicioNome = 'Desenvolvimento com Halteres',
    this.metaRepeticoes = 10,
    this.exercicioIndice = 1,
    this.totalExercicios = 1,
    this.proximoExercicioNome,
    this.listaExercicios,
    this.indiceInicial = 0,
  });

  @override
  State<CameraTreinoScreen> createState() => _CameraTreinoScreenState();
}

class _CameraTreinoScreenState extends State<CameraTreinoScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Timer? _timer;
  Timer? _feedbackTimer;
  bool _isSending = false;
  bool _isStreaming = true;
  bool _isLoading = true;
  String? _errorMessage;
  int _framesEnviados = 0;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;

  // Lista e Controle de Exercícios do Treino
  late List<Map<String, dynamic>> _exercicios;
  late int _indiceAtual;
  final Set<int> _indicesConcluidos = {};

  // Estado da IA e Avaliação Biomecânica
  int _repeticoes = 0;
  String _faseNome = 'Repouso';
  int _faseNumero = 0;
  String? _alertaImediato;
  bool _corpoVisivel = false;
  final String _lado = 'direito';
  Map<String, dynamic>? _ultimaRepeticao;
  Map<String, dynamic> _angulos = {};
  bool _mostrandoFeedbackSucesso = false;
  bool _isFinalizando = false;
  bool _isSimulando = false;

  // Telemetria e Diagnóstico em Tempo Real
  int _latenciaMs = 0;
  String _statusConexao = 'Iniciando IA...';
  bool _servidorConectado = false;

  // Serviços de Pose On-Device e WebSocket
  late final PoseService _poseService;
  IAWebSocketService? _wsService;
  final Stopwatch _latenciaSw = Stopwatch();

  Map<String, dynamic> get _exercicioAtual =>
      _exercicios.isNotEmpty ? _exercicios[_indiceAtual] : {};
  String get _exercicioIdAtual =>
      (_exercicioAtual['exercicio_id'] ?? _exercicioAtual['id'] ?? widget.exercicioId).toString();
  String get _exercicioNomeAtual =>
      _exercicioAtual['nome']?.toString() ?? widget.exercicioNome;
  int get _metaRepsAtual =>
      (_exercicioAtual['repeticoes'] as num?)?.toInt() ?? widget.metaRepeticoes;
  bool get _temProximoExercicio => (_indiceAtual + 1) < _exercicios.length;
  String? get _proximoExercicioNome =>
      _temProximoExercicio ? _exercicios[_indiceAtual + 1]['nome']?.toString() : null;

  @override
  void initState() {
    super.initState();
    if (widget.listaExercicios != null && widget.listaExercicios!.isNotEmpty) {
      _exercicios = List<Map<String, dynamic>>.from(widget.listaExercicios!);
      _indiceAtual = (widget.indiceInicial >= 0 && widget.indiceInicial < _exercicios.length)
          ? widget.indiceInicial
          : 0;
    } else {
      _exercicios = [
        {
          'exercicio_id': widget.exercicioId,
          'nome': widget.exercicioNome,
          'repeticoes': widget.metaRepeticoes,
        }
      ];
      _indiceAtual = 0;
    }
    _poseService = PoseService();
    _iniciarWebSocket();
    _iniciarSessaoIA();
    _setupCameras();
  }

  Future<void> _iniciarSessaoIA() async {
    try {
      final res = await ApiService().reiniciarSessaoIA(
        exercicioId: _exercicioIdAtual,
      );
      if (mounted && res['sucesso'] == true) {
        debugPrint('Sessão IA inicializada com sucesso: ${res['exercicio_nome']}');
      }
    } catch (e) {
      debugPrint('Aviso ao inicializar sessão IA: $e');
    }
  }

  Future<void> _avancarParaProximoExercicio() async {
    _indicesConcluidos.add(_indiceAtual);
    if (_temProximoExercicio) {
      setState(() {
        _indiceAtual++;
        _repeticoes = 0;
        _faseNome = 'Repouso';
        _faseNumero = 0;
        _alertaImediato = null;
        _ultimaRepeticao = null;
        _angulos = {};
        _mostrandoFeedbackSucesso = false;
        _isFinalizando = false;
        _isSending = false;
        _isStreaming = true;
        _statusConexao = 'Iniciando IA para novo exercício...';
      });

      // Notifica o backend via WebSocket (se conectado) ou REST para alternar exercício
      if (_wsService != null && _wsService!.conectado) {
        _wsService!.trocarExercicio(exercicioId: _exercicioIdAtual, lado: _lado);
      }
      await _iniciarSessaoIA();

      // Rearma o timer de envio periódico de frames da câmera para a IA
      if (!mounted) return;
      _startPeriodicSending();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Iniciando: $_exercicioNomeAtual'),
          backgroundColor: const Color(0xFF00E676),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setupCameras() async {
    try {
      if (widget.camera != null) {
        _availableCameras = [widget.camera!];
      } else {
        _availableCameras = await availableCameras();
      }

      if (_availableCameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Nenhuma câmera detectada no dispositivo.\nVocê pode utilizar o botão de Simulação para demonstrar a IA.';
          _isLoading = false;
        });
        return;
      }

      await _initController(_availableCameras[_currentCameraIndex]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao inicializar a câmera: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initController(CameraDescription cameraDescription) async {
    await _controller?.dispose();

    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.low, // Formato leve (~320x240, ~30KB) para tráfego ultrarrápido na internet
      enableAudio: false,
    );

    _controller = controller;
    _initializeControllerFuture = controller.initialize();

    try {
      await _initializeControllerFuture;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      _startPeriodicSending();
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('already exists')) {
        // Aguarda liberação do driver Media Foundation pelo SO e tenta novamente
        await Future.delayed(const Duration(milliseconds: 600));
        try {
          await _controller?.initialize();
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          _startPeriodicSending();
          return;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Falha ao conectar à câmera: $e';
        _isLoading = false;
      });
    }
  }

  void _iniciarWebSocket() {
    _wsService = IAWebSocketService(
      onResultado: _onResultadoIA,
      onStatusChanged: (status) {
        if (mounted) setState(() => _statusConexao = status);
      },
      onErro: (erro) {
        debugPrint('WebSocket IA erro: $erro');
      },
    );

    final uid = ApiService().idUsuarioAtual ?? 'anonimo';
    _wsService!.conectar(
      usuarioId: uid,
      exercicioId: _exercicioIdAtual,
      lado: _lado,
    );
  }

  void _onResultadoIA(Map<String, dynamic> res) {
    if (!mounted) return;

    final lat = _latenciaSw.elapsedMilliseconds;

    setState(() {
      _framesEnviados++;
      if (lat > 0) _latenciaMs = lat;
      _servidorConectado = true;
      _statusConexao = '🟢 IA Conectada (WS) • ${_latenciaMs}ms';
      _corpoVisivel = res['corpo_visivel'] ?? false;
      _repeticoes = (res['repeticoes'] as num?)?.toInt() ?? _repeticoes;
      _faseNome = res['fase_nome']?.toString() ?? _faseNome;
      _faseNumero = (res['fase_numero'] as num?)?.toInt() ?? _faseNumero;
      _alertaImediato = res['alerta_imediato']?.toString();

      if (res['angulos'] != null && res['angulos'] is Map) {
        _angulos = Map<String, dynamic>.from(res['angulos'] as Map);
      }

      if (res['repeticao_concluida'] == true) {
        _mostrandoFeedbackSucesso = true;
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _mostrandoFeedbackSucesso = false);
        });
      }

      if (res['ultima_repeticao'] != null && res['ultima_repeticao'] is Map) {
        _ultimaRepeticao = Map<String, dynamic>.from(res['ultima_repeticao'] as Map);
      }
    });
  }

  void _startPeriodicSending() {
    _timer?.cancel();

    // Em dispositivos móveis com MediaPipe on-device suportado (Android / iOS),
    // analisa a pose localmente e envia apenas os ângulos (JSON ~200 bytes) via WebSocket a cada 150ms (~7 FPS).
    // No Windows desktop ou plataformas sem ML Kit, mantém fallback seguro de envio de imagens via REST a cada 500ms.
    final bool usaOnDevice = _poseService.disponivel;
    final Duration intervalo = usaOnDevice
        ? const Duration(milliseconds: 150)
        : const Duration(milliseconds: 500);

    _timer = Timer.periodic(intervalo, (timer) async {
      if (!_isStreaming || _isSending || _isFinalizando) return;
      if (_controller == null || !_controller!.value.isInitialized) return;

      _isSending = true;
      if (mounted) setState(() {});

      File? tempFile;
      try {
        final XFile imageFile = await _controller!.takePicture();
        tempFile = File(imageFile.path);

        if (usaOnDevice && _wsService != null && _wsService!.conectado) {
          // Extração on-device com Google ML Kit Pose Detection
          final inputImage = InputImage.fromFilePath(imageFile.path);
          final poseRes = await _poseService.extrairAngulos(
            inputImage,
            exercicioId: _exercicioIdAtual,
            lado: _lado,
          );

          _latenciaSw.reset();
          _latenciaSw.start();

          if (poseRes != null) {
            _wsService!.enviarAngulos(poseRes.angulos, visivel: poseRes.visivel);
          } else {
            _wsService!.enviarAngulos({}, visivel: false);
          }
        } else {
          // Fallback seguro: Envia imagem completa para processamento no servidor (modo clássico)
          final bytes = await tempFile.readAsBytes();
          await _processarFrameNoBackend(bytes);
        }
      } catch (e) {
        debugPrint('Erro no loop de captura/envio da câmera: $e');
      } finally {
        try {
          if (tempFile != null && await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    });
  }

  Future<void> _processarFrameNoBackend(List<int> bytes) async {
    final sw = Stopwatch()..start();
    try {
      final res = await ApiService().processarFrameIA(
        imageBytes: bytes,
        exercicioId: _exercicioIdAtual,
        lado: _lado,
      );
      sw.stop();

      if (!mounted) return;

      final lat = sw.elapsedMilliseconds;

      if (res['sucesso'] == true) {
        setState(() {
          _framesEnviados++;
          _latenciaMs = lat;
          _servidorConectado = true;
          _statusConexao = '🟢 IA Conectada • ${_latenciaMs}ms';
          _corpoVisivel = res['corpo_visivel'] ?? false;
          _repeticoes = (res['repeticoes'] as num?)?.toInt() ?? _repeticoes;
          _faseNome = res['fase_nome']?.toString() ?? _faseNome;
          _faseNumero = (res['fase_numero'] as num?)?.toInt() ?? _faseNumero;
          _alertaImediato = res['alerta_imediato']?.toString();

          if (res['angulos'] != null && res['angulos'] is Map) {
            _angulos = Map<String, dynamic>.from(res['angulos'] as Map);
          }

          if (res['repeticao_concluida'] == true) {
            _mostrandoFeedbackSucesso = true;
            _feedbackTimer?.cancel();
            _feedbackTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _mostrandoFeedbackSucesso = false);
            });
          }

          if (res['ultima_repeticao'] != null && res['ultima_repeticao'] is Map) {
            _ultimaRepeticao = Map<String, dynamic>.from(res['ultima_repeticao'] as Map);
          }
        });
      } else {
        setState(() {
          _statusConexao = '🟡 ${res['mensagem'] ?? 'Processando...'}';
          if (res['alerta_imediato'] != null) {
            _alertaImediato = res['alerta_imediato'].toString();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _servidorConectado = false;
        _statusConexao = '🟠 Conectando ao servidor...';
        _alertaImediato = 'Servidor Render iniciando ou sem conexão...';
      });
      debugPrint('Falha ao processar frame no backend: $e');
    }
  }

  Future<void> _simularRepeticaoDemo() async {
    if (_isSimulando) return;
    setState(() => _isSimulando = true);

    try {
      final res = await ApiService().simularRepeticaoIA(
        exercicioId: _exercicioIdAtual,
        tipoCenario: 'ideal',
      );

      if (!mounted) return;

      if (res['sucesso'] == true) {
        setState(() {
          _repeticoes = (res['repeticoes'] as num?)?.toInt() ?? (_repeticoes + 1);
          _faseNome = 'Pico de Contração';
          _alertaImediato = res['alerta_imediato']?.toString();
          _mostrandoFeedbackSucesso = true;
          if (res['ultima_repeticao'] != null && res['ultima_repeticao'] is Map) {
            _ultimaRepeticao = Map<String, dynamic>.from(res['ultima_repeticao'] as Map);
          }
        });

        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _mostrandoFeedbackSucesso = false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repetição canônica validada pelo motor de IA!'),
            backgroundColor: Color(0xFF00E676),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na simulação: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulando = false);
    }
  }

  double _calcularProgressoMovimento() {
    if (_angulos.isEmpty) return 0.0;
    final nomeLower = _exercicioNomeAtual.toLowerCase();
    if (nomeLower.contains('agacha') ||
        nomeLower.contains('squat') ||
        nomeLower.contains('perna')) {
      final joelho = (_angulos['joelho'] as num?)?.toDouble() ?? 170.0;
      // Repouso: ~170°, Fundo do Agachamento: ~100°
      return ((170.0 - joelho) / (170.0 - 100.0)).clamp(0.0, 1.0);
    } else if (nomeLower.contains('rosca') ||
        nomeLower.contains('biceps') ||
        nomeLower.contains('bíceps')) {
      final cotovelo = (_angulos['cotovelo'] as num?)?.toDouble() ?? 160.0;
      // Repouso: ~160°, Topo da Flexão: ~80°
      return ((160.0 - cotovelo) / (160.0 - 80.0)).clamp(0.0, 1.0);
    } else {
      // Desenvolvimento com halteres: cotovelo de 85° a 165°
      final cotovelo = (_angulos['cotovelo'] as num?)?.toDouble() ?? 85.0;
      return ((cotovelo - 85.0) / (165.0 - 85.0)).clamp(0.0, 1.0);
    }
  }

  Future<void> _finalizarSerie() async {
    setState(() => _isFinalizando = true);
    _timer?.cancel();

    try {
      final res = await ApiService().finalizarSerieEPontuarIA(
        incrementarSequencia: true,
      );

      if (!mounted) return;

      final pontos = (res['pontos_atribuidos'] as num?)?.toInt() ?? 0;
      final resumo = res['resumo_ia'] as Map<String, dynamic>?;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.workspace_premium, color: Color(0xFF00E676), size: 28),
              SizedBox(width: 10),
              Text(
                'Série Concluída com IA',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercício: $_exercicioNomeAtual',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pontos Conquistados:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '+$pontos pts',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (resumo != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Repetições Aprovadas: ${resumo['repeticoes_aprovadas'] ?? _repeticoes}/${resumo['total_repeticoes'] ?? _repeticoes}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                if (resumo['score_medio'] != null)
                  Text(
                    'Score Médio DTW: ${((resumo['score_medio'] as num).toDouble()).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                const SizedBox(height: 8),
                if (resumo['recomendacao_prioritaria'] != null)
                  Text(
                    'Feedback Técnico: "${resumo['recomendacao_prioritaria']}"',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            if (_temProximoExercicio) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _indicesConcluidos.add(_indiceAtual);
                  Navigator.pop(ctx);
                  Navigator.pop(context, {
                    'concluido': true,
                    'acao': 'pausar',
                    'indicesConcluidos': _indicesConcluidos.toList(),
                  });
                },
                child: const Text('Pausar e Voltar'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _avancarParaProximoExercicio();
                },
                label: Text(
                  'Próximo: ${_proximoExercicioNome!}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.emoji_events, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _indicesConcluidos.add(_indiceAtual);
                  Navigator.pop(ctx);
                  Navigator.pop(context, {
                    'concluido': true,
                    'acao': 'finalizar_tudo',
                    'treinoConcluido': true,
                    'indicesConcluidos': _indicesConcluidos.toList(),
                  });
                },
                label: const Text('Concluir Treino Completo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar treino: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        // Retoma o envio contínuo caso o encerramento tenha falhado na rede
        _startPeriodicSending();
      }
    } finally {
      if (mounted) setState(() => _isFinalizando = false);
    }
  }

  void _toggleStreaming() {
    setState(() {
      _isStreaming = !_isStreaming;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isStreaming ? 'Transmissão com a IA retomada' : 'Transmissão pausada',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: _isStreaming ? const Color(0xFF00E676) : Colors.orangeAccent,
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;
    setState(() => _isLoading = true);
    await _initController(_availableCameras[_currentCameraIndex]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    _wsService?.desconectar();
    _poseService.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Feed da Câmera
            _buildCameraPreview(),

            // HUD Superior: Barra de Informações do Treino
            _buildTopBar(),

            // HUD Central: Card de Feedback Postural em Tempo Real
            _buildFeedbackOverlay(),

            // HUD Inferior: Controles de Treino e Simulação
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _simularRepeticaoDemo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Simular Repetição com IA'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text('Câmera não inicializada.', style: TextStyle(color: Colors.white)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWindows = Platform.isWindows;
        final previewRatio = _controller!.value.aspectRatio;

        return Center(
          child: AspectRatio(
            aspectRatio: isWindows ? previewRatio : (1 / previewRatio),
            child: CameraPreview(_controller!),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final totalEx = _exercicios.length;
    final numAtual = _indiceAtual + 1;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Voltar
          CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context, {
                  'concluido': _indicesConcluidos.isNotEmpty,
                  'indicesConcluidos': _indicesConcluidos.toList(),
                });
              },
            ),
          ),

          // Título do Exercício, Contador de Exercícios e Lado
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (totalEx > 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$numAtual/$totalEx',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Icon(Icons.fitness_center, color: Color(0xFF00E676), size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _exercicioNomeAtual,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Alternar Câmera
          if (_availableCameras.length > 1)
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: _switchCamera,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOverlay() {
    Color bannerColor;
    String feedbackText;
    IconData feedbackIcon;

    if (_mostrandoFeedbackSucesso) {
      bannerColor = const Color(0xFF00E676);
      feedbackText = '🎉 REPETIÇÃO VÁLIDA COM SUCESSO!';
      feedbackIcon = Icons.stars_rounded;
    } else if (!_servidorConectado && _framesEnviados == 0) {
      bannerColor = Colors.orangeAccent;
      feedbackText = _alertaImediato ?? 'Conectando ao servidor IA no Render...';
      feedbackIcon = Icons.cloud_sync;
    } else if (!_corpoVisivel && _framesEnviados > 0) {
      bannerColor = Colors.orangeAccent;
      feedbackText = 'Afaste-se da câmera (~1.5m a 2m) para enquadrar corpo e braços';
      feedbackIcon = Icons.accessibility_new;
    } else if (_alertaImediato != null && _alertaImediato!.isNotEmpty) {
      bannerColor = Colors.redAccent;
      feedbackText = _alertaImediato!;
      feedbackIcon = Icons.warning_amber_rounded;
    } else {
      bannerColor = const Color(0xFF00E676);
      feedbackText = 'Postura Correta • $_faseNome';
      feedbackIcon = Icons.check_circle_outline;
    }

    // Identificação visual da fase do exercício
    Color corFase = Colors.blueGrey;
    IconData iconeFase = Icons.radio_button_unchecked;
    final faseLower = _faseNome.toLowerCase();
    if (faseLower.contains('subind') || faseLower.contains('ascend')) {
      corFase = Colors.amber;
      iconeFase = Icons.arrow_upward;
    } else if (faseLower.contains('pico') || faseLower.contains('cont') || faseLower.contains('topo')) {
      corFase = const Color(0xFF00E676);
      iconeFase = Icons.local_fire_department;
    } else if (faseLower.contains('desc') || faseLower.contains('excen')) {
      corFase = Colors.purpleAccent;
      iconeFase = Icons.arrow_downward;
    }

    // Cálculo em tempo real do percentual de amplitude do movimento (0 a 100%)
    final progresso = _calcularProgressoMovimento();
    final progressoPct = (progresso * 100).toInt();

    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Banner de Alerta Postural em Tempo Real
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: bannerColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(feedbackIcon, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feedbackText,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_isSending)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Pílula de Telemetria e Diagnóstico da Conexão em Tempo Real
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusConexao,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_framesEnviados > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• $_framesEnviados frames',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Chips de Fase e Ângulos Biomecânicos em Tempo Real
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chip da Fase Atual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: corFase.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconeFase, color: corFase, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Fase: $_faseNome',
                      style: TextStyle(
                        color: corFase,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Chips de Ângulos
              if (_angulos.isNotEmpty) ...[
                const SizedBox(width: 6),
                ..._angulos.entries.take(2).map((entry) {
                  final nomeArt = entry.key.length > 7
                      ? entry.key.substring(0, 7)
                      : entry.key;
                  final ang = (entry.value as num).toStringAsFixed(0);
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      '$nomeArt: $ang°',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Barra de Progresso e Amplitude da Repetição em Tempo Real
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amplitude do Movimento:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$progressoPct%',
                      style: TextStyle(
                        color: progressoPct >= 80
                            ? const Color(0xFF00E676)
                            : (progressoPct >= 40 ? Colors.amber : Colors.cyanAccent),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressoPct >= 80
                          ? const Color(0xFF00E676)
                          : (progressoPct >= 40 ? Colors.amber : Colors.cyanAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Contador Gigante de Repetições
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00E676), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_repeticoes',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / $_metaRepsAtual REPS',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Nota da última repetição (se houver)
          if (_ultimaRepeticao != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Última Rep: ${(_ultimaRepeticao!['score_final'] as num?)?.toStringAsFixed(0) ?? '--'}% (${_ultimaRepeticao!['classificacao'] ?? 'OK'})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pausar / Retomar Streaming
            IconButton(
              iconSize: 28,
              icon: Icon(
                _isStreaming ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: _isStreaming ? Colors.orangeAccent : const Color(0xFF00E676),
              ),
              tooltip: _isStreaming ? 'Pausar IA' : 'Retomar IA',
              onPressed: _toggleStreaming,
            ),

            // Botão de Demonstração Instantânea (Banca / Avaliação)
            ElevatedButton.icon(
              onPressed: _isSimulando ? null : _simularRepeticaoDemo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: _isSimulando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bolt, color: Colors.amber, size: 18),
              label: const Text('Simular Rep', style: TextStyle(fontSize: 12)),
            ),

            // Botão Finalizar Série
            ElevatedButton.icon(
              onPressed: _isFinalizando ? null : _finalizarSerie,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: _isFinalizando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.check_circle, size: 18),
              label: const Text(
                'Finalizar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
