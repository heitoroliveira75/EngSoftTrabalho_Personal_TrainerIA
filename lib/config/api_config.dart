import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// URL do backend hospedado na nuvem (ex: Render).
  /// Para usar a API online, preencha com a URL do Render (ex: 'https://personal-trainer-api.onrender.com').
  /// Se deixado vazio, o aplicativo usa a conexão local automaticamente (localhost / 10.0.2.2).
  static const String remoteUrl = 'https://personai-docker.onrender.com';

  /// Retorna a URL base ativa da API REST.
  static String get baseUrl {
    // 1. Se uma URL remota foi configurada, ela tem prioridade em todas as plataformas
    if (remoteUrl.trim().isNotEmpty) {
      return remoteUrl.trim();
    }

    // 2. Modo local de desenvolvimento
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 é o alias do emulador Android para acessar o localhost da máquina host
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Caso não seja possível identificar a plataforma, fallback para localhost
    }
    return 'http://127.0.0.1:8000';
  }

  /// Retorna a URL base para conexões WebSocket (wss:// em produção, ws:// em desenvolvimento local).
  static String get wsBaseUrl {
    if (remoteUrl.trim().isNotEmpty) {
      final trimmed = remoteUrl.trim();
      if (trimmed.startsWith('https://')) {
        return trimmed.replaceFirst('https://', 'wss://');
      } else if (trimmed.startsWith('http://')) {
        return trimmed.replaceFirst('http://', 'ws://');
      }
      return 'wss://$trimmed';
    }

    if (kIsWeb) {
      return 'ws://127.0.0.1:8000';
    }
    try {
      if (Platform.isAndroid) {
        return 'ws://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'ws://127.0.0.1:8000';
  }
}
