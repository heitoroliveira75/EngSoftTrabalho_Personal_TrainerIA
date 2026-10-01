import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'change_name_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ===========================================================================
  // DADOS DO USUÁRIO
  // ===========================================================================
  late String nomeUsuario;
  late String emailUsuario;
  bool _carregando = false;

  // Métricas de desempenho (futura expansão no banco)
  int pontosTotais = 2000;
  int pontosHoje = 150;
  int pontosSemana = 250;
  int diasSequencia = 2;

  @override
  void initState() {
    super.initState();
    nomeUsuario = ApiService().nomeUsuarioAtual;
    emailUsuario = ApiService().emailUsuarioAtual;
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final usuarioId = ApiService().idUsuarioAtual;
    if (usuarioId != null) {
      final res = await ApiService().verPerfil(usuarioId);
      if (mounted && res['sucesso'] == true && res['perfil'] != null) {
        final perfil = res['perfil'] as Map<String, dynamic>;
        setState(() {
          if (perfil['nome'] != null && perfil['nome'].toString().trim().isNotEmpty) {
            nomeUsuario = perfil['nome'].toString().trim();
          }
          if (perfil['email'] != null && perfil['email'].toString().trim().isNotEmpty) {
            emailUsuario = perfil['email'].toString().trim();
          }
        });
      }
    } else {
      final res = await ApiService().obterUsuarioAtual();
      if (mounted && res['sucesso'] == true && res['usuario'] != null) {
        setState(() {
          nomeUsuario = ApiService().nomeUsuarioAtual;
          emailUsuario = ApiService().emailUsuarioAtual;
        });
      }
    }
  }

  Future<void> _executarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232A),
        title: const Text('Deslogar', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Deseja realmente sair da sua conta?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _carregando = true);
      await ApiService().deslogar();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final letraAvatar = nomeUsuario.trim().isNotEmpty
        ? nomeUsuario.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Seta de voltar + texto "PERFIL" clicáveis
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'PERFIL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card com dados do utilizador
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF8A5CF5),
                    child: Text(
                      letraAvatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nomeUsuario,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (emailUsuario.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      emailUsuario,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64B5F6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Seu Desempenho',
                    style: TextStyle(
                      color: Color(0xFF8A5CF5),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$pontosTotais pts',
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Hoje', '$pontosHoje pts'),
                  _buildStatRow('Semana', '$pontosSemana pts'),
                  _buildStatRow('Sequência', '$diasSequencia dias'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Conta',
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Redirecionamento para Alterar Nome
            _buildOptionButton(
              title: 'Alterar o nome',
              onTap: () async {
                final alterou = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangeNameScreen(),
                  ),
                );
                if (alterou == true) {
                  _carregarPerfil();
                }
              },
            ),
            const SizedBox(height: 12),

            // Redirecionamento para Alterar Senha
            _buildOptionButton(
              title: 'Alterar a senha',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Botão Deslogar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3139),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _carregando ? null : _executarLogout,
                child: _carregando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.redAccent,
                        ),
                      )
                    : const Text(
                        'Deslogar',
                        style: TextStyle(color: Colors.redAccent, fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D3139),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
