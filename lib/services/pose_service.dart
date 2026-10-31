import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Resultado da extração de pose e cálculo angular biomecânico.
class PoseResultado {
  final Map<String, double> angulos;
  final bool visivel;

  const PoseResultado({
    required this.angulos,
    required this.visivel,
  });
}

/// Equivalente Dart multiplataforma de calculo_angulos.py.
/// Extrai marcos anatômicos e calcula ângulos articulares diretamente no dispositivo móvel (on-device).
class PoseService {
  PoseDetector? _detector;
  bool _detectorInicializado = false;

  /// Retorna se o processamento on-device está disponível na plataforma atual.
  /// O Google ML Kit Pose Detection é nativamente suportado em Android e iOS.
  bool get disponivel {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  PoseDetector _obterDetector() {
    if (!_detectorInicializado) {
      _detector = PoseDetector(
        options: PoseDetectorOptions(
          model: PoseDetectionModel.base, // Equivalente leve (pose_landmarker_lite)
          mode: PoseDetectionMode.stream, // Otimizado para pipeline contínuo de vídeo
        ),
      );
      _detectorInicializado = true;
    }
    return _detector!;
  }

  /// Equivalente exato a calcular_angulo(A, B, C) de calculo_angulos.py.
  /// B é o vértice da articulação. Retorna o ângulo convexo em graus no intervalo [0°, 180°].
  double _calcularAngulo(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;

    final distBa = sqrt(baX * baX + baY * baY);
    final distBc = sqrt(bcX * bcX + bcY * bcY);

    if (distBa == 0.0 || distBc == 0.0) {
      return 0.0;
    }

    final produtoEscalar = (baX * bcX) + (baY * bcY);
    final cosTheta = (produtoEscalar / (distBa * distBc)).clamp(-1.0, 1.0);
    return acos(cosTheta) * 180.0 / pi;
  }

  bool _landmarkVisivel(PoseLandmark? lm) {
    if (lm == null) return false;
    return lm.likelihood >= 0.5;
  }

  /// Equivalente a extrair_angulos_exercicio() do calculo_angulos.py.
  /// Retorna os ângulos biomecânicos em graus e flag de visibilidade.
  /// Retorna null se nenhuma pose for detectada ou se o hardware não for suportado.
  Future<PoseResultado?> extrairAngulos(
    InputImage imagem, {
    required String exercicioId,
    String lado = 'direito',
  }) async {
    if (!disponivel) return null;

    List<Pose> poses;
    try {
      poses = await _obterDetector().processImage(imagem);
    } catch (e) {
      debugPrint('PoseService: Erro ao inferir pose: $e');
      return null;
    }

    if (poses.isEmpty) return null;

    final lm = poses.first.landmarks;
    final esq = lado.toLowerCase() == 'esquerdo';

    // Marcos anatômicos principais
    final ombro = lm[esq ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
    final cotovelo = lm[esq ? PoseLandmarkType.leftElbow : PoseLandmarkType.rightElbow];
    final punho = lm[esq ? PoseLandmarkType.leftWrist : PoseLandmarkType.rightWrist];
    final quadril = lm[esq ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final joelho = lm[esq ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final tornozelo = lm[esq ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];

    final exId = exercicioId.trim().toLowerCase();

    // 1. Exercícios de membros superiores: Desenvolvimento com Halteres (16 / 1) e Rosca Direta (20 / 3)
    if (exId == '16' || exId == '20' || exId == '1' || exId == '3' ||
        exId.contains('ombro') || exId.contains('rosca') || exId.contains('biceps')) {
      if (ombro == null || cotovelo == null || punho == null || quadril == null) {
        return null;
      }

      final visivelBraco = _landmarkVisivel(ombro) &&
                           _landmarkVisivel(cotovelo) &&
                           _landmarkVisivel(punho);

      final angCotovelo = _calcularAngulo(ombro, cotovelo, punho);
      final angOmbro = _calcularAngulo(quadril, ombro, cotovelo);

      Map<String, double> angulos = {
        'cotovelo': double.parse(angCotovelo.toStringAsFixed(1)),
        'ombro': double.parse(angOmbro.toStringAsFixed(1)),
      };
      bool visivelFinal = visivelBraco;

      // Suporte inteligente contralateral: verifica se o outro braço está mais ativo/visível
      final outroOmbro = lm[esq ? PoseLandmarkType.rightShoulder : PoseLandmarkType.leftShoulder];
      final outroCotovelo = lm[esq ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow];
      final outroPunho = lm[esq ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist];
      final outroQuadril = lm[esq ? PoseLandmarkType.rightHip : PoseLandmarkType.leftHip];

      if (outroOmbro != null && outroCotovelo != null && outroPunho != null && outroQuadril != null) {
        final visivelOutro = _landmarkVisivel(outroOmbro) &&
                             _landmarkVisivel(outroCotovelo) &&
                             _landmarkVisivel(outroPunho);

        if (visivelOutro) {
          final outroCotoveloAng = _calcularAngulo(outroOmbro, outroCotovelo, outroPunho);
          // Se o lado padrão não estava visível ou se o outro braço tem flexão mais pronunciada
          if (!visivelBraco || outroCotoveloAng < (angCotovelo - 8.0)) {
            final outroOmbroAng = _calcularAngulo(outroQuadril, outroOmbro, outroCotovelo);
            angulos = {
              'cotovelo': double.parse(outroCotoveloAng.toStringAsFixed(1)),
              'ombro': double.parse(outroOmbroAng.toStringAsFixed(1)),
            };
            visivelFinal = true;
          }
        }
      }

      return PoseResultado(
        angulos: angulos,
        visivel: visivelFinal,
      );
    }

    // 2. Exercícios de membros inferiores: Agachamento Livre (11 / 2)
    if (exId == '11' || exId == '2' || exId.contains('agacha') || exId.contains('squat')) {
      if (quadril == null || joelho == null || tornozelo == null || ombro == null) {
        return null;
      }

      final visivelPerna = _landmarkVisivel(quadril) &&
                           _landmarkVisivel(joelho) &&
                           _landmarkVisivel(tornozelo);

      final angJoelho = _calcularAngulo(quadril, joelho, tornozelo);
      final angQuadril = _calcularAngulo(ombro, quadril, joelho);

      return PoseResultado(
        angulos: {
          'joelho': double.parse(angJoelho.toStringAsFixed(1)),
          'quadril': double.parse(angQuadril.toStringAsFixed(1)),
        },
        visivel: visivelPerna,
      );
    }

    return null;
  }

  /// Libera recursos do motor de pose quando não for mais utilizado.
  void dispose() {
    if (_detectorInicializado && _detector != null) {
      _detector!.close();
      _detector = null;
      _detectorInicializado = false;
    }
  }
}
