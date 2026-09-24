import 'package:flutter/material.dart';

import 'change_name_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS (Substitua no futuro pelos dados vindos do banco de dados)
  // ===========================================================================
  String nomeUsuario = 'João Almeida';
  String emailUsuario = 'jpo.almeida@unifesp.br';
  int pontosTotais = 1850;
  int pontosHoje = 150;
  int pontosSemana = 250;
  int diasSequencia = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Seta de voltar + texto "PERFIL" clicáveis
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('PERFIL'),
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
                      nomeUsuario.isNotEmpty
                          ? nomeUsuario[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nomeUsuario,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    emailUsuario,
                    style: const TextStyle(
                      color: Color(0xFF64B5F6),
                      fontSize: 14,
                    ),
                  ),
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
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Redirecionamento para Alterar Nome
            _buildOptionButton(
              title: 'Alterar o nome',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangeNameScreen(),
                  ),
                );
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
                onPressed: () {
                  // Ação de logout e retorno à home
                  Navigator.pop(context);
                },
                child: const Text(
                  'Deslogar',
                  style: TextStyle(color: Colors.red, fontSize: 18),
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
        trailing: const Icon(Icons.arrow_forward, color: Colors.white),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF2196F3), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
