import 'package:flutter/material.dart';
import 'profile_screen.dart';

class criar_exercicio_screen extends StatefulWidget {
  const criar_exercicio_screen({super.key});

  @override
  State<criar_exercicio_screen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<criar_exercicio_screen> {
  // ===========================================================================
  // VARIÁVEIS DE DADOS (Substitua no futuro pelos dados vindos do banco de dados)
  // ===========================================================================
  int pontosTotais = 1850;
  int pontosSemana = 250;
  int maiorSequencia = 6;
  int sequenciaAtual = 2;
  int pontosHoje = 150;
  int metaHoje = 200;

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
    );
  }

}
