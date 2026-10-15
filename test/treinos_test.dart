import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/exercicio_treino.dart';
import 'package:flutter_application_1/screens/dificuldade_treino_screen.dart';
import 'package:flutter_application_1/screens/training_menu_screen.dart';
import 'package:flutter_application_1/screens/opcao_treinos_screen.dart';

void main() {
  group('ExercicioTreino Model Tests', () {
    test('Calcula totais de repetições e pontos corretamente', () {
      final exercicio = ExercicioTreino(
        id: '1',
        nome: 'Supino Reto',
        grupoMuscular: 'Peitoral',
        series: 4,
        repeticoes: 10,
        pontosPorSerie: 50,
        pontosPorRepeticao: 5,
      );

      expect(exercicio.totalRepeticoes, 40);
      expect(exercicio.pontosSeries, 200); // 4 * 50
      expect(exercicio.pontosRepeticoes, 200); // 40 * 5
      expect(exercicio.totalPontos, 400); // 200 + 200

      final json = exercicio.toJson();
      expect(json['exercicio_id'], '1');
      expect(json['nome'], 'Supino Reto');
      expect(json['pontos_totais'], 400);

      final recriado = ExercicioTreino.fromJson(json);
      expect(recriado.id, '1');
      expect(recriado.nome, 'Supino Reto');
      expect(recriado.series, 4);
      expect(recriado.repeticoes, 10);
      expect(recriado.totalPontos, 400);
    });
  });

  group('Workout Screens Widget Smoke Tests', () {
    testWidgets('TrainingMenuScreen renderiza opções', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrainingMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TREINO'), findsOneWidget);
      expect(find.text('Meus Treinos'), findsOneWidget);
      expect(find.text('Criar Treinos'), findsOneWidget);
      expect(find.text('Treinos Padrões'), findsOneWidget);
    });

    testWidgets('DificuldadeScreen renderiza os 3 níveis', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DificuldadeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INICIANTE'), findsOneWidget);
      expect(find.text('INTERMEDIÁRIO'), findsOneWidget);
      expect(find.text('AVANÇADO'), findsOneWidget);
    });

    testWidgets('OpcaoTreinosScreen renderiza treinos de iniciante', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OpcaoTreinosScreen(dificuldadeFlag: 'iniciante'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INICIANTE'), findsOneWidget);
      expect(find.text('Corpo completo A'), findsOneWidget);
    });
  });
}
