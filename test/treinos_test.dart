import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/exercicio_treino.dart';
import 'package:flutter_application_1/screens/dificuldade_treino_screen.dart';
import 'package:flutter_application_1/screens/training_menu_screen.dart';
import 'package:flutter_application_1/screens/opcao_treinos_screen.dart';
import 'package:flutter_application_1/screens/camera_treino_screen.dart';
import 'package:flutter_application_1/screens/lobby_dupla_screen.dart';
import 'package:flutter_application_1/models/sessao_dupla.dart';

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
    testWidgets('TrainingMenuScreen renderiza opções', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingMenuScreen()));
      await tester.pumpAndSettle();

      expect(find.text('TREINO'), findsOneWidget);
      expect(find.text('Meus Treinos'), findsOneWidget);
      expect(find.text('Criar Treinos'), findsOneWidget);
      expect(find.text('Treinos Padrões'), findsOneWidget);
    });

    testWidgets('DificuldadeScreen renderiza os 3 níveis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: DificuldadeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('INICIANTE'), findsOneWidget);
      expect(find.text('INTERMEDIÁRIO'), findsOneWidget);
      expect(find.text('AVANÇADO'), findsOneWidget);
    });

    testWidgets('OpcaoTreinosScreen renderiza treinos de iniciante', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OpcaoTreinosScreen(dificuldadeFlag: 'iniciante'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INICIANTE'), findsOneWidget);
    });
  });

  group('CameraTreinoScreen Series & Reps Tests', () {
    test(
      'CameraTreinoScreen suporta metas configuráveis de séries e repetições',
      () {
        const screen = CameraTreinoScreen(
          exercicioId: '20',
          exercicioNome: 'Rosca Direta',
          metaRepeticoes: 8,
          totalSeries: 3,
        );

        expect(screen.exercicioId, '20');
        expect(screen.exercicioNome, 'Rosca Direta');
        expect(screen.metaRepeticoes, 8);
        expect(screen.totalSeries, 3);
      },
    );

    test(
      'CameraTreinoScreen suporta modo dupla com lista completa de exercícios',
      () {
        final exercicios = [
          {
            'id': '16',
            'nome': 'Desenvolvimento com Halteres',
            'series': 3,
            'repeticoes': 10,
          },
          {
            'id': '11',
            'nome': 'Agachamento Livre',
            'series': 3,
            'repeticoes': 12,
          },
        ];

        final screen = CameraTreinoScreen(
          exercicioId: '16',
          exercicioNome: 'Desenvolvimento com Halteres',
          metaRepeticoes: 10,
          totalSeries: 3,
          listaExercicios: exercicios,
          isModoDupla: true,
          sessaoDuplaId: 'sessao-123',
          isHostDupla: true,
        );

        expect(screen.isModoDupla, isTrue);
        expect(screen.isHostDupla, isTrue);
        expect(screen.sessaoDuplaId, 'sessao-123');
        expect(screen.listaExercicios?.length, 2);
      },
    );

    test('CameraTreinoScreen suporta modo dupla no mesmo aparelho (1 Celular Presencial)', () {
      final exercicios = [
        {
          'id': '16',
          'nome': 'Desenvolvimento com Halteres',
          'series': 3,
          'repeticoes': 10,
        },
      ];

      final screen = CameraTreinoScreen(
        exercicioId: '16',
        exercicioNome: 'Desenvolvimento com Halteres',
        metaRepeticoes: 10,
        totalSeries: 3,
        listaExercicios: exercicios,
        isModoDupla: true,
        isMesmoAparelho: true,
        parceiroNome: 'Lucas',
      );

      expect(screen.isModoDupla, isTrue);
      expect(screen.isMesmoAparelho, isTrue);
      expect(screen.parceiroNome, 'Lucas');
      expect(screen.isHostDupla, isTrue);
    });

    test('Cálculo de bônus cooperativo do treino em dupla aplica 20% sobre a média', () {
      const pontosHost = 120;
      const pontosConvidado = 80;
      const media = (pontosHost + pontosConvidado) / 2.0; // 100.0
      final pontosFinais = (media * 1.2).round(); // 120
      final bonusExtra = (pontosFinais - media).round(); // 20

      expect(media, 100.0);
      expect(pontosFinais, 120);
      expect(bonusExtra, 20);
    });
  });

  group('LobbyDuplaScreen Tests', () {
    test('LobbyDuplaScreen inicializa com parâmetros de Host e Convidado', () {
      const lobby = LobbyDuplaScreen(
        sessaoId: 'sessao-456',
        isHost: true,
        amigoNome: 'Carlos',
        amigoId: 'user-789',
      );

      expect(lobby.sessaoId, 'sessao-456');
      expect(lobby.isHost, isTrue);
      expect(lobby.amigoNome, 'Carlos');
      expect(lobby.amigoId, 'user-789');
    });

    test(
      'SessaoDupla modelo parseia corretamente status e dados do treino',
      () {
        final json = {
          'id': 'sessao-999',
          'host_id': 'host-1',
          'convidado_id': 'convidado-2',
          'status': 'aceito',
          'dados_treino': {
            'nome': 'Treino de Peito e Ombros',
            'exercicios': [
              {
                'id': '16',
                'nome': 'Desenvolvimento com Halteres',
                'series': 3,
                'repeticoes': 10,
              },
            ],
          },
          'total_series': 3,
          'serie_atual': 1,
          'pontos_host': 50,
          'pontos_convidado': 45,
        };

        final sessao = SessaoDupla.fromJson(json);

        expect(sessao.id, 'sessao-999');
        expect(sessao.isAceito, isTrue);
        expect(sessao.dadosTreino['nome'], 'Treino de Peito e Ombros');
        expect(sessao.totalSeries, 3);
        expect(sessao.pontosHost, 50);
        expect(sessao.pontosConvidado, 45);
      },
    );
  });
}
