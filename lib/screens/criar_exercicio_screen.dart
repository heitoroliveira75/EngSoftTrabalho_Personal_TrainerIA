import 'package:flutter/material.dart';
import '../services/api_service.dart';

class criar_exercicio_screen extends StatefulWidget {
  const criar_exercicio_screen({super.key});

  @override
  State<criar_exercicio_screen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<criar_exercicio_screen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS (Substitua no futuro pelos dados vindos do banco de dados)
  // ===========================================================================
  int pontosTreino = 1850;
  final TextEditingController _nomeexercicio = TextEditingController();

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
          child: const Text('TREINOS'),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            // 1 Campo Nome do exercicio
            _buildInputField(
              controller: _nomeexercicio,
              hintText: 'Dê um nome ao seu treino',
              keyboardType: TextInputType.text,
            ),
            
            const SizedBox(height: 6),

            // 2 Texto de pontos
            Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                textAlign: TextAlign.start,
                TextSpan(
                  text: 'Total de pontos: ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: '$pontosTreino',
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3 exercicios
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Exemplo de exercício na lista
                    Material(
                      color: const Color(0xFF2D3139),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          print('Exercício selecionado!');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: const Row(
                            children: [
                              Icon(Icons.fitness_center, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Supino Reto', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // DOIS BOTÕES NO FIM DA TELA (Fininhos e discretos - Opção B)
            // ==========================================
            
            // 1º Botão (Adicionar)
            Material(
              color: const Color(0xFF2D3139),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  print('Adicionar exercício clicado');
                },
                child: Container(
                  width: double.infinity,
                  height: 38, // Altura fininha e discreta (38px)
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Salvar Treino',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8), // Espaçamento compacto

            // 2º Botão (Salvar Treino)
            Material(
              color: const Color(0xFF2D3139),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  print('Salvar treino clicado');
                },
                child: Container(
                  width: double.infinity,
                  height: 38, // Mesma altura de 38px
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Excluir treino',
                        style: TextStyle(
                          color: Color.fromARGB(255, 195, 18, 18),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
        filled: true,
        fillColor: Color(0xFF2D3139),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

}
