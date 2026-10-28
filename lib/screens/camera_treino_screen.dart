import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/api_service.dart';

class CameraTreinoScreen extends StatefulWidget {
  final CameraDescription? camera;
  final String? endpoint;
  final String exercicioId;
  final String exercicioNome;
  final int metaRepeticoes;

  const CameraTreinoScreen({
    super.key,
    this.camera,
    this.endpoint,
    this.exercicioId = '1',
    this.exercicioNome = 'Desenvolvimento de Ombros',
    this.metaRepeticoes = 10,
  });

  @override
  State<CameraTreinoScreen> createState() => _CameraTreinoScreenState();
}

class _CameraTreinoScreenState extends State<CameraTreinoScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Timer? _timer;
  bool _isSending = false;
  bool _isStreaming = true;
  bool _isLoading = true;
  String? _errorMessage;
  int _framesEnviados = 0;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;

  // Estado da IA e Avaliação Biomecânica
  int _repeticoes = 0;
  String _faseNome = 'Repouso';
  int _faseNumero = 0;
  String? _alertaImediato;
  bool _corpoVisivel = false;
  final String _lado = 'direito';
  Map<String, dynamic>? _ultimaRepeticao;
  bool _isFinalizando = false;
  bool _isSimulando = false;

  @override
  void initState() {
    super.initState();
    _iniciarSessaoIA();
    _setupCameras();
  }

  Future<void> _iniciarSessaoIA() async {
    try {
      final res = await ApiService().reiniciarSessaoIA(
        exercicioId: widget.exercicioId,
      );
      if (mounted && res['sucesso'] == true) {
        debugPrint('Sessão IA inicializada com sucesso: ${res['exercicio_nome']}');
      }
    } catch (e) {
      debugPrint('Aviso ao inicializar sessão IA: $e');
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
      ResolutionPreset.medium,
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
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Falha ao conectar à câmera: $e';
        _isLoading = false;
      });
    }
  }

  void _startPeriodicSending() {
    _timer?.cancel();
    // Envia um frame a cada 1.5 segundo para processamento em tempo real
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (!_isStreaming || _isSending || _isFinalizando) return;
      if (_controller == null || !_controller!.value.isInitialized) return;

      _isSending = true;
      if (mounted) setState(() {});

      File? tempFile;
      try {
        final XFile imageFile = await _controller!.takePicture();
        tempFile = File(imageFile.path);
        final bytes = await tempFile.readAsBytes();

        await _processarFrameNoBackend(bytes);
      } catch (e) {
        debugPrint('Erro ao capturar ou enviar frame: $e');
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
    try {
      final res = await ApiService().processarFrameIA(
        imageBytes: bytes,
        exercicioId: widget.exercicioId,
        lado: _lado,
      );

      if (!mounted) return;

      if (res['sucesso'] == true) {
        setState(() {
          _framesEnviados++;
          _corpoVisivel = res['corpo_visivel'] ?? false;
          _repeticoes = (res['repeticoes'] as num?)?.toInt() ?? _repeticoes;
          _faseNome = res['fase_nome']?.toString() ?? _faseNome;
          _faseNumero = (res['fase_numero'] as num?)?.toInt() ?? _faseNumero;
          _alertaImediato = res['alerta_imediato']?.toString();

          if (res['ultima_repeticao'] != null && res['ultima_repeticao'] is Map) {
            _ultimaRepeticao = Map<String, dynamic>.from(res['ultima_repeticao'] as Map);
          }
        });
      }
    } catch (e) {
      debugPrint('Falha ao processar frame no backend: $e');
    }
  }

  Future<void> _simularRepeticaoDemo() async {
    if (_isSimulando) return;
    setState(() => _isSimulando = true);

    try {
      final res = await ApiService().simularRepeticaoIA(
        exercicioId: widget.exercicioId,
        tipoCenario: 'ideal',
      );

      if (!mounted) return;

      if (res['sucesso'] == true) {
        setState(() {
          _repeticoes = (res['repeticoes'] as num?)?.toInt() ?? (_repeticoes + 1);
          _faseNome = 'Concluído';
          _alertaImediato = res['alerta_imediato']?.toString();
          if (res['ultima_repeticao'] != null && res['ultima_repeticao'] is Map) {
            _ultimaRepeticao = Map<String, dynamic>.from(res['ultima_repeticao'] as Map);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repetição canônica simulada no motor de IA com sucesso!'),
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
                'Exercício: ${widget.exercicioNome}',
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              child: const Text('Concluir e Voltar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Título do Exercício e Lado
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
                  const Icon(Icons.fitness_center, color: Color(0xFF00E676), size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.exercicioNome,
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

    if (!_corpoVisivel && _framesEnviados > 0) {
      bannerColor = Colors.orangeAccent;
      feedbackText = 'Posicione seu corpo por completo no enquadramento';
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

          const SizedBox(height: 12),

          // Contador Gigante de Repetições
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / ${widget.metaRepeticoes} REPS',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
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
