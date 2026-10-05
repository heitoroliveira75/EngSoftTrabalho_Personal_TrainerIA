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

  String get nomeUsuarioAtual {
    if (usuarioLogado != null) {
      if (usuarioLogado!['nome'] != null &&
          usuarioLogado!['nome'].toString().trim().isNotEmpty) {
        return usuarioLogado!['nome'].toString().trim();
      }
      if (usuarioLogado!['user_metadata'] != null &&
          usuarioLogado!['user_metadata'] is Map &&
          usuarioLogado!['user_metadata']['nome'] != null &&
          usuarioLogado!['user_metadata']['nome'].toString().trim().isNotEmpty) {
        return usuarioLogado!['user_metadata']['nome'].toString().trim();
      }
    }
    return 'Usuário';
  }

  String get emailUsuarioAtual {
    if (usuarioLogado != null && usuarioLogado!['email'] != null) {
      return usuarioLogado!['email'].toString().trim();
    }
    return '';
  }

  String? get idUsuarioAtual {
    if (usuarioLogado != null && usuarioLogado!['id'] != null) {
      return usuarioLogado!['id'].toString();
    }
    return null;
  }

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
      if (data['sucesso'] == true && data['usuario'] != null) {
        usuarioLogado = Map<String, dynamic>.from(data['usuario'] as Map);
      }
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
      if (data['sucesso'] == true && data['usuario'] != null) {
        usuarioLogado = Map<String, dynamic>.from(data['usuario'] as Map);
      }
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

  /// Altera a senha do usuário com a senha atual
  Future<Map<String, dynamic>> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    String? email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/alterar-senha');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'senha_atual': senhaAtual,
              'nova_senha': novaSenha,
              if (email != null) 'email': email,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao alterar senha: $e',
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
      if (data['sucesso'] == true && data['perfil'] != null) {
        if (usuarioLogado == null) {
          usuarioLogado = Map<String, dynamic>.from(data['perfil'] as Map);
        } else {
          usuarioLogado!.addAll(Map<String, dynamic>.from(data['perfil'] as Map));
        }
      }
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao obter perfil: $e',
      };
    }
  }

  /// Atualiza nome, CPF, sequência, maior sequência e/ou checagem do usuário
  Future<Map<String, dynamic>> editarPerfil(
    String usuarioId, {
    String? nome,
    String? cpf,
    int? sequencia,
    int? maiorSequencia,
    bool? checagem,
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
              if (sequencia != null) 'sequencia': sequencia,
              if (maiorSequencia != null) 'maior_sequencia': maiorSequencia,
              if (checagem != null) 'checagem': checagem,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['sucesso'] == true) {
        if (usuarioLogado != null) {
          if (nome != null) {
            usuarioLogado!['nome'] = nome;
            if (usuarioLogado!['user_metadata'] is Map) {
              (usuarioLogado!['user_metadata'] as Map)['nome'] = nome;
            }
          }
          if (cpf != null) {
            usuarioLogado!['cpf'] = cpf;
          }
          if (sequencia != null) {
            usuarioLogado!['sequencia'] = sequencia;
          }
          if (maiorSequencia != null) {
            usuarioLogado!['maior_sequencia'] = maiorSequencia;
          }
          if (checagem != null) {
            usuarioLogado!['checagem'] = checagem;
          }
        }
      }
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

  // ============================================================
  // 5. PONTUAÇÕES / GAMIFICAÇÃO
  // ============================================================

  int get pontuacaoDiariaAtual {
    if (usuarioLogado != null && usuarioLogado!['pontuacao_diaria'] != null) {
      return (usuarioLogado!['pontuacao_diaria'] as num).toInt();
    }
    return 0;
  }

  int get pontuacaoSemanalAtual {
    if (usuarioLogado != null && usuarioLogado!['pontuacao_semanal'] != null) {
      return (usuarioLogado!['pontuacao_semanal'] as num).toInt();
    }
    return 0;
  }

  int get pontuacaoTotalAtual {
    if (usuarioLogado != null && usuarioLogado!['pontuacao_total'] != null) {
      return (usuarioLogado!['pontuacao_total'] as num).toInt();
    }
    return 0;
  }

  int get sequenciaAtual {
    if (usuarioLogado != null && usuarioLogado!['sequencia'] != null) {
      return (usuarioLogado!['sequencia'] as num).toInt();
    }
    return 0;
  }

  int get maiorSequenciaAtual {
    if (usuarioLogado != null && usuarioLogado!['maior_sequencia'] != null) {
      return (usuarioLogado!['maior_sequencia'] as num).toInt();
    }
    return 0;
  }

  bool get checagemAtual {
    if (usuarioLogado != null && usuarioLogado!['checagem'] != null) {
      return usuarioLogado!['checagem'] == true;
    }
    return false;
  }

  /// Consulta as pontuações (diária, semanal e total), sequência, maior sequência e checagem de um usuário
  Future<Map<String, dynamic>> verPontuacao(String usuarioId) async {
    try {
      final url = Uri.parse('$baseUrl/pontuacao/$usuarioId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['sucesso'] == true) {
        usuarioLogado ??= {};
        if (data['pontuacao_diaria'] != null) {
          usuarioLogado!['pontuacao_diaria'] = data['pontuacao_diaria'];
        }
        if (data['pontuacao_semanal'] != null) {
          usuarioLogado!['pontuacao_semanal'] = data['pontuacao_semanal'];
        }
        if (data['pontuacao_total'] != null) {
          usuarioLogado!['pontuacao_total'] = data['pontuacao_total'];
        }
        if (data['sequencia'] != null) {
          usuarioLogado!['sequencia'] = data['sequencia'];
        }
        if (data['maior_sequencia'] != null) {
          usuarioLogado!['maior_sequencia'] = data['maior_sequencia'];
        }
        if (data['checagem'] != null) {
          usuarioLogado!['checagem'] = data['checagem'];
        }
      }
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao buscar pontuações: $e',
        'pontuacao_diaria': 0,
        'pontuacao_semanal': 0,
        'pontuacao_total': 0,
        'sequencia': 0,
        'maior_sequencia': 0,
        'checagem': false,
      };
    }
  }

  /// Adiciona pontuação diária ao usuário, atualizando semanal, total, checagem, sequência e maior sequência
  Future<Map<String, dynamic>> adicionarPontuacaoDiaria({
    required String usuarioId,
    int pontos = 50,
    bool? incrementarSequencia,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pontuacao/diaria');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'usuario_id': usuarioId,
              'pontos': pontos,
              if (incrementarSequencia != null)
                'incrementar_sequencia': incrementarSequencia,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['sucesso'] == true) {
        usuarioLogado ??= {};
        if (data['pontuacao_diaria'] != null) {
          usuarioLogado!['pontuacao_diaria'] = data['pontuacao_diaria'];
        }
        if (data['pontuacao_semanal'] != null) {
          usuarioLogado!['pontuacao_semanal'] = data['pontuacao_semanal'];
        }
        if (data['pontuacao_total'] != null) {
          usuarioLogado!['pontuacao_total'] = data['pontuacao_total'];
        }
        if (data['sequencia'] != null) {
          usuarioLogado!['sequencia'] = data['sequencia'];
        }
        if (data['maior_sequencia'] != null) {
          usuarioLogado!['maior_sequencia'] = data['maior_sequencia'];
        }
        if (data['checagem'] != null) {
          usuarioLogado!['checagem'] = data['checagem'];
        }
      }
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao adicionar pontuação diária: $e',
      };
    }
  }

  /// Atualiza diretamente a quantidade de dias da sequência do usuário
  Future<Map<String, dynamic>> atualizarSequencia({
    required String usuarioId,
    required int sequencia,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pontuacao/sequencia');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'usuario_id': usuarioId,
              'sequencia': sequencia,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['sucesso'] == true) {
        usuarioLogado ??= {};
        usuarioLogado!['sequencia'] = sequencia;
        if (data['maior_sequencia'] != null) {
          usuarioLogado!['maior_sequencia'] = data['maior_sequencia'];
        }
      }
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao atualizar sequência: $e',
      };
    }
  }

  /// Atualiza diretamente o recorde de maior sequência em dias do usuário
  Future<Map<String, dynamic>> atualizarMaiorSequencia({
    required String usuarioId,
    required int maiorSequencia,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pontuacao/maior-sequencia');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'usuario_id': usuarioId,
              'maior_sequencia': maiorSequencia,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['sucesso'] == true) {
        usuarioLogado ??= {};
        usuarioLogado!['maior_sequencia'] = maiorSequencia;
      }
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao atualizar maior sequência: $e',
      };
    }
  }

  /// Atualiza diretamente o valor booleano da checagem
  Future<Map<String, dynamic>> atualizarChecagem({
    required String usuarioId,
    required bool checagem,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pontuacao/checagem');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'usuario_id': usuarioId,
              'checagem': checagem,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['sucesso'] == true) {
        usuarioLogado ??= {};
        usuarioLogado!['checagem'] = checagem;
      }
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao atualizar checagem: $e',
      };
    }
  }

  /// Reseta a checagem diária do usuário para false
  Future<Map<String, dynamic>> resetarChecagem(String usuarioId) async {
    try {
      final url = Uri.parse('$baseUrl/pontuacao/$usuarioId/resetar-checagem');
      final response = await http
          .post(url, headers: _headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['sucesso'] == true) {
        usuarioLogado ??= {};
        usuarioLogado!['checagem'] = false;
      }
      return data;
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao resetar checagem: $e',
      };
    }
  }
}

