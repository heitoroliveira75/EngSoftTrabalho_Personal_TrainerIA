import 'package:flutter/material.dart';

class TreinoSelecionadoScreen extends StatefulWidget {
  final Map<String, dynamic> treinoData;

  const TreinoSelecionadoScreen({super.key, required this.treinoData});

  @override
  State<TreinoSelecionadoScreen> createState() =>
      _TreinoSelecionadoScreenState();
}

class _TreinoSelecionadoScreenState extends State<TreinoSelecionadoScreen> {
  bool _salvo = false;

  @override
  Widget build(BuildContext context) {
    final Color corTema =
        widget.treinoData['corTema'] ?? const Color(0xFF00E676);
    final List exercicios = widget.treinoData['exercicios'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TREINO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.treinoData['titulo'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.treinoData['dificuldade'],
                style: TextStyle(
                  color: corTema,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.treinoData['exerciciosCount']} exercícios, ${widget.treinoData['duracaoMinutos']} minutos',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 16),

              const Text(
                'Exercício',
                style: TextStyle(
                  color: Color(0xFF9E7AFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercicios.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ex = exercicios[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex['nome'],
                              style: const TextStyle(
                                color: Color(0xFF29B6F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ex['series']} séries × ${ex['repeticoes']}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${ex['pontos']} pts',
                        style: TextStyle(
                          color: corTema,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              InkWell(
                onTap: () {
                  setState(() {
                    _salvo = !_salvo;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _salvo
                            ? 'Treino salvo nos meus Treinos!'
                            : 'Treino removido dos salvos.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _salvo ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _salvo
                          ? 'Salvo nos meus Treinos'
                          : 'Salvar nos meu Treinos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: corTema, width: 2),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    'TREINAR',
                    style: TextStyle(
                      color: corTema,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
