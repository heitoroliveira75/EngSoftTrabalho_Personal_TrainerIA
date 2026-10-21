import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_service.dart';

class CameraTreinoScreen extends StatefulWidget {
  final CameraDescription? camera;
  final String? endpoint;

  const CameraTreinoScreen({super.key, this.camera, this.endpoint});

  @override
  State<CameraTreinoScreen> createState() => _CameraTreinoScreenState();
}

class _CameraTreinoScreenState extends State<CameraTreinoScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Timer? _timer;
  bool _isSending = false;
  bool _isStreaming = true; // Controla se o envio periódico está ativo
  bool _isLoading = true;
  String? _errorMessage;
  int _framesEnviados = 0;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupCameras();
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
          _errorMessage = 'Nenhuma câmera detectada no dispositivo.';
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
      ResolutionPreset.medium, // Resolução moderada para poupar rede e latência
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
    // Envia um frame a cada 2 segundos para análise na API
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isStreaming || _isSending) return;
      if (_controller == null || !_controller!.value.isInitialized) return;

      _isSending = true;
      if (mounted) setState(() {});

      File? tempFile;
      try {
        final XFile imageFile = await _controller!.takePicture();
        tempFile = File(imageFile.path);

        // Envia o frame capturado para o backend
        await _sendFrameToApi(tempFile);
      } catch (e) {
        debugPrint('Erro ao capturar ou enviar frame: $e');
      } finally {
        // Exclui o arquivo temporário salvo para economizar espaço de armazenamento
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

  Future<void> _sendFrameToApi(File file) async {
    try {
      final uri = Uri.parse(
        widget.endpoint ?? '${ApiConfig.baseUrl}/ia/processar-frame',
      );

      final request = http.MultipartRequest('POST', uri);

      // Anexa o arquivo de imagem na requisição sob o campo 'frame'
      request.files.add(await http.MultipartFile.fromPath('frame', file.path));

      // Anexa metadados úteis caso o usuário esteja autenticado
      final usuarioId = ApiService().idUsuarioAtual;
      if (usuarioId != null && usuarioId.isNotEmpty) {
        request.fields['usuario_id'] = usuarioId;
      }
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 5),
      );

      if (streamedResponse.statusCode == 200) {
        debugPrint('Frame enviado com sucesso!');
        if (mounted) {
          setState(() {
            _framesEnviados++;
          });
        }
      } else {
        debugPrint('Erro na resposta da API: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Falha na conexão de envio do frame: $e');
    }
  }

  void _toggleStreaming() {
    setState(() {
      _isStreaming = !_isStreaming;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isStreaming
              ? 'Transmissão de frames retomada'
              : 'Transmissão de frames pausada',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: _isStreaming
            ? const Color(0xFF00E676)
            : Colors.orangeAccent,
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;

    setState(() {
      _isLoading = true;
      _currentCameraIndex =
          (_currentCameraIndex + 1) % _availableCameras.length;
    });

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
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text(
          'Câmera de Treino',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_availableCameras.length > 1)
            IconButton(
              icon: const Icon(
                Icons.cameraswitch_outlined,
                color: Colors.white,
              ),
              tooltip: 'Alternar Câmera',
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E676)),
            SizedBox(height: 16),
            Text(
              'Inicializando câmera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _setupCameras,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          'Câmera indisponível',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Stack(
      children: [
        // Preview da Câmera adaptada para Desktop (Webcam) e Mobile
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Center(
              child: isDesktop
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    )
                  : FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize?.height ?? 1,
                        height: _controller!.value.previewSize?.width ?? 1,
                        child: CameraPreview(_controller!),
                      ),
                    ),
            ),
          ),
        ),

        // Barra Superior de Status / Badges
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge de Status da Transmissão
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isStreaming
                        ? const Color(0xFF00E676)
                        : Colors.orangeAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isStreaming
                            ? (_isSending
                                  ? Colors.lightGreenAccent
                                  : const Color(0xFF00E676))
                            : Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isStreaming
                          ? (_isSending
                                ? 'Enviando Frame...'
                                : 'IA Monitorando')
                          : 'Pausado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Contador de Frames
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Frames: $_framesEnviados',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Painel Inferior de Controles
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pausar / Retomar envio
                IconButton(
                  iconSize: 32,
                  icon: Icon(
                    _isStreaming
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: _isStreaming
                        ? Colors.orangeAccent
                        : const Color(0xFF00E676),
                  ),
                  tooltip: _isStreaming
                      ? 'Pausar Transmissão'
                      : 'Retomar Transmissão',
                  onPressed: _toggleStreaming,
                ),

                // Botão de Captura Manual Imediata
                ElevatedButton.icon(
                  onPressed: _isSending
                      ? null
                      : () async {
                          if (_controller != null &&
                              _controller!.value.isInitialized) {
                            setState(() => _isSending = true);
                            try {
                              final img = await _controller!.takePicture();
                              final file = File(img.path);
                              await _sendFrameToApi(file);
                              if (await file.exists()) await file.delete();
                            } finally {
                              if (mounted) setState(() => _isSending = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text(
                    'Enviar Agora',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
