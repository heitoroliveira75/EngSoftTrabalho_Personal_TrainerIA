import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Configuração padrão de IP/Host
  // - No Emulador Android: use 'http://10.0.2.2:8000'
  // - No iOS Simulator / Chrome Web / Windows Desktop: use 'http://127.0.0.1:8000'
  // - Em celular físico via Wi-Fi: substitua pelo IP da sua máquina (ex: 'http://192.168.1.100:8000')
  
  static String get baseUrl {
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
}
