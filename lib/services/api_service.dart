import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => ApiConfig.baseUrl;

  // Dados em memória da sessão atual
  String? tokenAcesso;
  Map<String, dynamic>? usuarioLogado;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        if (tokenAcesso != null) 'Authorization': 'Bearer $tokenAcesso',
      };

  // ============================================================
  // 1. AUTENTICAÇÃO E SESSÃO
  // ============================================================

  /// Cria uma nova conta chamando o endpoint Python /auth/criar-conta
  Future<Map<String, dynamic>> criarConta({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/criar-conta');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'senha': senha,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao conectar ao servidor: $e',
      };
    }
  }

  /// Realiza login chamando o endpoint Python /auth/login
  Future<Map<String, dynamic>> fazerLogin({
    required String email,
    required String senha,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'senha': senha,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (data['sucesso'] == true) {
        usuarioLogado = data['usuario'];
        if (data['sessao'] != null && data['sessao']['access_token'] != null) {
          tokenAcesso = data['sessao']['access_token'];
        }
      }

      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao conectar ao servidor: $e',
      };
    }
  }

  /// Desloga o usuário chamando o endpoint Python /auth/logout
  Future<Map<String, dynamic>> deslogar() async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout');
      final response = await http
          .post(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      tokenAcesso = null;
      usuarioLogado = null;

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      tokenAcesso = null;
      usuarioLogado = null;
      return {
        'sucesso': false,
        'mensagem': 'Erro ao comunicar logout: $e',
      };
    }
  }

  /// Obtém o usuário autenticado atualmente no backend
  Future<Map<String, dynamic>> obterUsuarioAtual() async {
    try {
      final url = Uri.parse('$baseUrl/auth/usuario-atual');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao buscar usuário atual: $e',
      };
    }
  }

  /// Solicita recuperação de senha via email
  Future<Map<String, dynamic>> esqueceuSenha({required String email}) async {
    try {
      final url = Uri.parse('$baseUrl/auth/esqueceu-senha');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao solicitar recuperação de senha: $e',
      };
    }
  }

  /// Redefine a senha informando código e nova senha
  Future<Map<String, dynamic>> redefinirSenha({
    String? email,
    String? codigo,
    required String novaSenha,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/redefinir-senha');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              if (email != null) 'email': email,
              if (codigo != null) 'codigo': codigo,
              'nova_senha': novaSenha,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao redefinir senha: $e',
      };
    }
  }

  // ============================================================
  // 2. PERFIL DE USUÁRIO
  // ============================================================

  /// Consulta dados cadastrais do perfil pelo ID do usuário
  Future<Map<String, dynamic>> verPerfil(String usuarioId) async {
    try {
      final url = Uri.parse('$baseUrl/perfil/$usuarioId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao obter perfil: $e',
      };
    }
  }

  /// Atualiza nome e/ou CPF do usuário
  Future<Map<String, dynamic>> editarPerfil(
    String usuarioId, {
    String? nome,
    String? cpf,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/perfil/$usuarioId');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({
              if (nome != null) 'nome': nome,
              if (cpf != null) 'cpf': cpf,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao atualizar perfil: $e',
      };
    }
  }

  // ============================================================
  // 3. EXERCÍCIOS
  // ============================================================

  /// Lista exercícios cadastrados com filtro opcional de grupo muscular
  Future<Map<String, dynamic>> listarExercicios({String? grupoMuscular}) async {
    try {
      final uri = Uri.parse('$baseUrl/exercicios').replace(
        queryParameters: {
          if (grupoMuscular != null && grupoMuscular.isNotEmpty)
            'grupo_muscular': grupoMuscular,
        },
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao listar exercícios: $e',
        'exercicios': [],
      };
    }
  }

  // ============================================================
  // 4. TREINOS
  // ============================================================

  /// Retorna os treinos pré-montados do sistema
  Future<Map<String, dynamic>> verTreinosPremontados() async {
    try {
      final url = Uri.parse('$baseUrl/treinos/pre-montados');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao buscar treinos pré-montados: $e',
        'treinos': [],
      };
    }
  }

  /// Retorna os treinos criados por um determinado usuário
  Future<Map<String, dynamic>> listarTreinosUsuario(String usuarioId) async {
    try {
      final url = Uri.parse('$baseUrl/treinos/usuario/$usuarioId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao listar treinos do usuário: $e',
        'treinos': [],
      };
    }
  }

  /// Cria um novo treino com lista opcional de exercícios
  Future<Map<String, dynamic>> criarTreino({
    String? usuarioId,
    required String nome,
    String? descricao,
    bool preMontado = false,
    List<Map<String, dynamic>>? exercicios,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/treinos');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              if (usuarioId != null) 'usuario_id': usuarioId,
              'nome': nome,
              'descricao': descricao ?? '',
              'pre_montado': preMontado,
              if (exercicios != null) 'exercicios': exercicios,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao criar treino: $e',
      };
    }
  }

  /// Edita um treino existente
  Future<Map<String, dynamic>> editarTreino(
    dynamic treinoId, {
    String? nome,
    String? descricao,
    List<Map<String, dynamic>>? exercicios,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/treinos/$treinoId');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({
              if (nome != null) 'nome': nome,
              if (descricao != null) 'descricao': descricao,
              if (exercicios != null) 'exercicios': exercicios,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao editar treino: $e',
      };
    }
  }

  /// Exclui um treino pelo ID
  Future<Map<String, dynamic>> excluirTreino(dynamic treinoId) async {
    try {
      final url = Uri.parse('$baseUrl/treinos/$treinoId');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao excluir treino: $e',
      };
    }
  }
}
