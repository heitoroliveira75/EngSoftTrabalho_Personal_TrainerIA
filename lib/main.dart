import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Treino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(
          0xFF0D1117,
        ), // Fundo escuro das imagens
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF161B22),
          primary: Colors.blueAccent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/* ============================================================================
   1. TELA HOME
   ============================================================================ */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'HOME',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 36),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card Pontos Totais
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'Pontos Totais',
                    style: TextStyle(
                      color: Color(0xFF8A5CF5),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1850 pts',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '+250 pts essa semana',
                    style: TextStyle(color: Color(0xFF64B5F6), fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3 Métricas lado a lado
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    value: '6',
                    label: 'Maior\nSequência',
                    labelColor: Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.bolt,
                    iconColor: Colors.amberAccent,
                    value: '2',
                    label: 'Sequência',
                    labelColor: Colors.pinkAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber,
                    value: '150',
                    label: 'Pts Hoje',
                    labelColor: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Meta de Hoje
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3139),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meta de Hoje',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      '150/200 pts',
                      style: TextStyle(color: Color(0xFF00E676), fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 150 / 200,
                      minHeight: 16,
                      backgroundColor: Colors.grey,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botão Hora de Treinar
            InkWell(
              onTap: () {
                // Ação ao clicar no treino
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3139),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: Color(0xFF00E676),
                    ),
                    SizedBox(width: 16),
                    Container(height: 50, width: 2, color: Colors.grey),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora de',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Treinar',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3139),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: labelColor),
          ),
        ],
      ),
    );
  }
}

/* ============================================================================
   2. TELA PERFIL
   ============================================================================ */
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('PERFIL'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Branco com Dados do Usuário
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF8A5CF5),
                    child: Text(
                      'J',
                      style: TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'João Almeida',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'jpo.almeida@unifesp.br',
                    style: TextStyle(color: Color(0xFF64B5F6), fontSize: 14),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Seu Desempenho',
                    style: TextStyle(
                      color: Color(0xFF8A5CF5),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '1850 pts',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _StatRow(label: 'Hoje', value: '150 pts'),
                  _StatRow(label: 'Semana', value: '250 pts'),
                  _StatRow(label: 'Sequência', value: '2 dias'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Conta',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Botão Alterar Nome
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

            // Botão Alterar Senha
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
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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

/* ============================================================================
   3. TELA ALTERAR NOME
   ============================================================================ */
class ChangeNameScreen extends StatelessWidget {
  const ChangeNameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: 'João Pedro Almeida');
    final newNameController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ALTERAR NOME'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF8A5CF5),
                    child: Text(
                      'J',
                      style: TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildWhiteCardTextField(
                    label: 'Nome Atual',
                    controller: nameController,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  _buildWhiteCardTextField(
                    label: 'Novo Nome',
                    controller: newNameController,
                    hintText: 'Digite o seu novo nome',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                  Navigator.pop(context);
                },
                child: const Text(
                  'Salvar',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================================
   4. TELA ALTERAR SENHA
   ============================================================================ */
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ALTERAR SENHA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF8A5CF5),
                    child: Text(
                      'J',
                      style: TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildWhiteCardTextField(
                    label: 'Senha Atual',
                    controller: currentPassController,
                    hintText: 'Digite a sua senha',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  _buildWhiteCardTextField(
                    label: 'Nova Senha',
                    controller: newPassController,
                    hintText: 'Digite a nova senha',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  _buildWhiteCardTextField(
                    label: 'Confirmar Senha',
                    controller: confirmPassController,
                    hintText: 'Confirme a nova senha',
                    isPassword: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                  Navigator.pop(context);
                },
                child: const Text(
                  'Salvar',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================================
   WIDGET AUXILIAR PARA CAMPOS DE TEXTO
   ============================================================================ */
Widget _buildWhiteCardTextField({
  required String label,
  required TextEditingController controller,
  String? hintText,
  bool enabled = true,
  bool isPassword = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2196F3),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 40,
        child: TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword,
          style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF90CAF9), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black54),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF2196F3)),
              borderRadius: BorderRadius.circular(4),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black38),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    ],
  );
}
