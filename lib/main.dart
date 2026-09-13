import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (HOME + Ícone de Usuário)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HOME',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. Card de Nível
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Nível ',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Color(0xFF8A52F3),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: '7',
                                style: TextStyle(
                                  fontSize: 42,
                                  color: Color(0xFF8A52F3),
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '300/350',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: 300 / 350,
                        minHeight: 18,
                        backgroundColor: const Color(0xFF5A5A5A),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 3. Grid dos 3 Cards (Estrelas, Sequência, Exercícios)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        icon: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 55,
                        ),
                        value: '2',
                        valueColor: Colors.amber,
                        label: 'Estrelas',
                        labelColor: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStatCard(
                        icon: const Icon(
                          Icons.flash_on,
                          color: Color(0xFFFFD700),
                          size: 55,
                        ),
                        value: '3',
                        valueColor: const Color(0xFFFF5252),
                        label: 'Sequência',
                        labelColor: const Color(0xFFFF5252),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStatCard(
                        icon: const Icon(
                          Icons.fitness_center,
                          color: Colors.orangeAccent,
                          size: 45,
                        ),
                        value: '9',
                        valueColor: Colors.orangeAccent,
                        label: 'Exercícios',
                        labelColor: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 4. Grid dos 2 Cards (Primeiro Treino e Básico Completo)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAchievementCard(
                        title: 'Primeiro\nTreino',
                        subtitle: 'Tudo começa com\num único passo',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAchievementCard(
                        title: 'Básico\nCompleto',
                        subtitle: 'Começamos em\nalgum lugar',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 5. Card Inferior ("Hora de Treinar")
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00FF87), Color(0xFF60EFFF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Container(height: 70, width: 1.5, color: Colors.white54),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Hora de',
                            style: TextStyle(
                              fontSize: 22,
                              color: Color(0xFF00FF87),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            'Treinar',
                            style: TextStyle(
                              fontSize: 34,
                              color: Color(0xFF00FF87),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required Widget icon,
    required String value,
    required Color valueColor,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 55, child: Center(child: icon)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 60),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
