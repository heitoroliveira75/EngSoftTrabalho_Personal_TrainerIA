"""
Script para Reset e Povoamento do Banco de Dados com Exercícios e Treinos compatíveis com a IA.
Executa a limpeza das tabelas 'treino_exercicios', 'treinos' e 'exercicios',
e insere os 30 exercícios mestre respeitando rigorosamente os IDs utilizados pela IA:
  - ID 1: Desenvolvimento com Halteres (IA - Ombros)
  - ID 2: Agachamento Livre (IA - Pernas)
  - ID 3: Rosca Direta (IA - Bíceps)
  - IDs 4 a 30: Peito, Costas, Pernas, Ombros, Braços e Abdômen
"""

import sys
import json
from pathlib import Path

# Garante que o diretório BD esteja no path para importar o cliente Supabase
DIRETORIO_BD = Path(__file__).resolve().parent
if str(DIRETORIO_BD) not in sys.path:
    sys.path.insert(0, str(DIRETORIO_BD))

from supabase_client import supabase

def popular_banco():
    print("==================================================")
    print("Iniciando reset e povoamento do banco de dados...")
    print("==================================================")

    # 1. Limpeza das tabelas (ordem inversa de dependência)
    try:
        print("1. Limpando tabela 'treino_exercicios'...")
        supabase.table("treino_exercicios").delete().neq("id", 0).execute()
        
        print("2. Limpando tabela 'treinos'...")
        supabase.table("treinos").delete().neq("id", 0).execute()

        print("3. Limpando tabela 'exercicios'...")
        supabase.table("exercicios").delete().neq("id", 0).execute()
        print("✓ Tabelas limpas com sucesso!")
    except Exception as e:
        print(f"Aviso durante a limpeza: {e}")

    # 2. Inserção dos 30 Exercícios
    exercicios = [
        # ================= IA CORE (IDs 1, 2 e 3) =================
        {
            "id": 1,
            "nome": "Desenvolvimento com Halteres",
            "descricao": "Press vertical para deltoides com monitoramento biomecânico de cotovelos e ombros pela IA.",
            "grupo_muscular": "Ombros"
        },
        {
            "id": 2,
            "nome": "Agachamento Livre",
            "descricao": "Exercício composto para quadríceps e glúteos com validação de amplitude e alinhamento pela IA.",
            "grupo_muscular": "Pernas"
        },
        {
            "id": 3,
            "nome": "Rosca Direta",
            "descricao": "Flexão de cotovelos com halteres ou barra com análise de trajetória angular pela IA.",
            "grupo_muscular": "Bíceps"
        },
        # ================= PEITORAL =================
        {
            "id": 4,
            "nome": "Supino Reto",
            "descricao": "Exercício básico composto com barra ou halteres.",
            "grupo_muscular": "Peitoral"
        },
        {
            "id": 5,
            "nome": "Supino Inclinado",
            "descricao": "Foco na porção clavicular (superior) do peitoral.",
            "grupo_muscular": "Peitoral"
        },
        {
            "id": 6,
            "nome": "Crucifixo Reto",
            "descricao": "Abertura com halteres no banco reto para isolamento peitoral.",
            "grupo_muscular": "Peitoral"
        },
        {
            "id": 7,
            "nome": "Crossover na Polia",
            "descricao": "Isolamento de peitoral com cabos na polia regulável.",
            "grupo_muscular": "Peitoral"
        },
        {
            "id": 8,
            "nome": "Flexão de Braço",
            "descricao": "Exercício funcional de peitoral e core com peso corporal.",
            "grupo_muscular": "Peitoral"
        },
        # ================= COSTAS =================
        {
            "id": 9,
            "nome": "Puxada Frontal",
            "descricao": "Puxada alta na polia com pegada aberta para dorsais.",
            "grupo_muscular": "Costas"
        },
        {
            "id": 10,
            "nome": "Remada Baixa",
            "descricao": "Remada sentado na polia com triângulo para densidade de dorsais.",
            "grupo_muscular": "Costas"
        },
        {
            "id": 11,
            "nome": "Remada Curvada",
            "descricao": "Remada livre com barra ou halteres para ativação de costas.",
            "grupo_muscular": "Costas"
        },
        {
            "id": 12,
            "nome": "Barra Fixa",
            "descricao": "Elevação corporal na barra fixa com pegada pronada.",
            "grupo_muscular": "Costas"
        },
        {
            "id": 13,
            "nome": "Pulldown",
            "descricao": "Isolamento de grandes dorsais na polia com barra reta ou corda.",
            "grupo_muscular": "Costas"
        },
        # ================= PERNAS =================
        {
            "id": 14,
            "nome": "Leg Press 45°",
            "descricao": "Prensa inclinada para membros inferiores e quadríceps.",
            "grupo_muscular": "Pernas"
        },
        {
            "id": 15,
            "nome": "Cadeira Extensora",
            "descricao": "Isolamento de quadríceps em máquina extensora.",
            "grupo_muscular": "Pernas"
        },
        {
            "id": 16,
            "nome": "Mesa Flexora",
            "descricao": "Isolamento de posteriores de coxa (isquiotibiais).",
            "grupo_muscular": "Pernas"
        },
        {
            "id": 17,
            "nome": "Panturrilha em Pé",
            "descricao": "Elevação plantar para panturrilhas em máquina ou degrau.",
            "grupo_muscular": "Pernas"
        },
        # ================= OMBROS =================
        {
            "id": 18,
            "nome": "Elevação Lateral",
            "descricao": "Foco no deltoide medial/lateral com halteres.",
            "grupo_muscular": "Ombros"
        },
        {
            "id": 19,
            "nome": "Elevação Frontal",
            "descricao": "Foco no deltoide anterior com halteres ou anilha.",
            "grupo_muscular": "Ombros"
        },
        {
            "id": 20,
            "nome": "Crucifixo Invertido",
            "descricao": "Foco no deltoide posterior e romboides.",
            "grupo_muscular": "Ombros"
        },
        # ================= BÍCEPS =================
        {
            "id": 21,
            "nome": "Rosca Alternada",
            "descricao": "Flexão alternada de cotovelos com halteres e supinação.",
            "grupo_muscular": "Bíceps"
        },
        {
            "id": 22,
            "nome": "Rosca Martelo",
            "descricao": "Pegada neutra para ativação do braquial e antebraço.",
            "grupo_muscular": "Bíceps"
        },
        {
            "id": 23,
            "nome": "Rosca Scott",
            "descricao": "Isolamento no banco Scott evitando impulsos.",
            "grupo_muscular": "Bíceps"
        },
        # ================= TRÍCEPS =================
        {
            "id": 24,
            "nome": "Tríceps Corda",
            "descricao": "Extensão de cotovelos na polia alta com corda.",
            "grupo_muscular": "Tríceps"
        },
        {
            "id": 25,
            "nome": "Tríceps Pulley",
            "descricao": "Extensão na polia alta com barra reta ou V.",
            "grupo_muscular": "Tríceps"
        },
        {
            "id": 26,
            "nome": "Tríceps Testa",
            "descricao": "Extensão deitado com halteres ou barra W.",
            "grupo_muscular": "Tríceps"
        },
        {
            "id": 27,
            "nome": "Mergulho no Banco",
            "descricao": "Extensão de tríceps apoiado em banco com peso corporal.",
            "grupo_muscular": "Tríceps"
        },
        # ================= ABDÔMEN & CORE =================
        {
            "id": 28,
            "nome": "Abdominal Supra",
            "descricao": "Flexão de tronco no solo para reto abdominal.",
            "grupo_muscular": "Abdômen"
        },
        {
            "id": 29,
            "nome": "Prancha Abdominal",
            "descricao": "Isometria de core no solo em decúbito ventral.",
            "grupo_muscular": "Abdômen"
        },
        {
            "id": 30,
            "nome": "Elevação de Pernas",
            "descricao": "Foco na porção infra-abdominal e flexores de quadril.",
            "grupo_muscular": "Abdômen"
        }
    ]

    print(f"\nInserindo catálogo oficial com {len(exercicios)} exercícios...")
    for ex in exercicios:
        try:
            supabase.table("exercicios").insert(ex).execute()
            print(f"  [+] #{ex['id']:02d}: {ex['nome']} ({ex['grupo_muscular']})")
        except Exception as e:
            print(f"  [!] Erro ao inserir exercício #{ex['id']}: {e}")

    # 3. Inserção dos Treinos Pré-montados
    treinos = [
        {
            "id": 1,
            "usuario_id": None,
            "nome": "Iniciante: Superiores & Ombros IA",
            "pre_montado": True,
            "descricao": json.dumps({
                "dificuldade": "Iniciante",
                "duracao_minutos": 30,
                "pontos_totais": 150,
                "texto": "Foco em membros superiores com acompanhamento biomecânico em tempo real pela IA.",
                "exercicios": [
                    {"exercicio_id": 1, "nome": "Desenvolvimento com Halteres", "series": 3, "repeticoes": 10, "pontos": 50},
                    {"exercicio_id": 3, "nome": "Rosca Direta", "series": 3, "repeticoes": 12, "pontos": 50},
                    {"exercicio_id": 29, "nome": "Prancha Abdominal", "series": 3, "repeticoes": 30, "pontos": 50}
                ]
            }, ensure_ascii=False)
        },
        {
            "id": 2,
            "usuario_id": None,
            "nome": "Iniciante: Pernas & Core IA",
            "pre_montado": True,
            "descricao": json.dumps({
                "dificuldade": "Iniciante",
                "duracao_minutos": 35,
                "pontos_totais": 160,
                "texto": "Treino de pernas com análise de amplitude e profundidade do agachamento pela IA.",
                "exercicios": [
                    {"exercicio_id": 2, "nome": "Agachamento Livre", "series": 3, "repeticoes": 12, "pontos": 60},
                    {"exercicio_id": 14, "nome": "Leg Press 45°", "series": 3, "repeticoes": 12, "pontos": 50},
                    {"exercicio_id": 28, "nome": "Abdominal Supra", "series": 3, "repeticoes": 15, "pontos": 50}
                ]
            }, ensure_ascii=False)
        },
        {
            "id": 3,
            "usuario_id": None,
            "nome": "Intermediário: Full Body IA Biomecânica",
            "pre_montado": True,
            "descricao": json.dumps({
                "dificuldade": "Intermediário",
                "duracao_minutos": 45,
                "pontos_totais": 250,
                "texto": "Treino completo integrando os 3 exercícios chave monitorados pela visão computacional.",
                "exercicios": [
                    {"exercicio_id": 1, "nome": "Desenvolvimento com Halteres", "series": 4, "repeticoes": 10, "pontos": 70},
                    {"exercicio_id": 2, "nome": "Agachamento Livre", "series": 4, "repeticoes": 12, "pontos": 70},
                    {"exercicio_id": 3, "nome": "Rosca Direta", "series": 4, "repeticoes": 10, "pontos": 60},
                    {"exercicio_id": 8, "nome": "Flexão de Braço", "series": 3, "repeticoes": 12, "pontos": 50}
                ]
            }, ensure_ascii=False)
        },
        {
            "id": 4,
            "usuario_id": None,
            "nome": "Avançado: Hipertrofia & Força Total IA",
            "pre_montado": True,
            "descricao": json.dumps({
                "dificuldade": "Avançado",
                "duracao_minutos": 55,
                "pontos_totais": 350,
                "texto": "Rotina intensa com alta cadência e validação técnica em tempo real pela IA.",
                "exercicios": [
                    {"exercicio_id": 2, "nome": "Agachamento Livre", "series": 4, "repeticoes": 15, "pontos": 80},
                    {"exercicio_id": 1, "nome": "Desenvolvimento com Halteres", "series": 4, "repeticoes": 12, "pontos": 80},
                    {"exercicio_id": 3, "nome": "Rosca Direta", "series": 4, "repeticoes": 12, "pontos": 70},
                    {"exercicio_id": 18, "nome": "Elevação Lateral", "series": 4, "repeticoes": 12, "pontos": 60},
                    {"exercicio_id": 24, "nome": "Tríceps Corda", "series": 4, "repeticoes": 15, "pontos": 60}
                ]
            }, ensure_ascii=False)
        }
    ]

    print("\nInserindo 4 treinos oficiais pré-montados...")
    for tr in treinos:
        try:
            supabase.table("treinos").insert(tr).execute()
            print(f"  [+] Treino #{tr['id']}: {tr['nome']}")
        except Exception as e:
            print(f"  [!] Erro ao inserir treino #{tr['id']}: {e}")

    # 4. Inserção das Relações em treino_exercicios
    relacoes = [
        # Treino 1 (Iniciante Superiores & Ombros IA)
        {"treino_id": 1, "exercicio_id": 1, "ordem": 1, "series": 3, "repeticoes": 10},
        {"treino_id": 1, "exercicio_id": 3, "ordem": 2, "series": 3, "repeticoes": 12},
        {"treino_id": 1, "exercicio_id": 29, "ordem": 3, "series": 3, "repeticoes": 30},
        # Treino 2 (Iniciante Pernas & Core IA)
        {"treino_id": 2, "exercicio_id": 2, "ordem": 1, "series": 3, "repeticoes": 12},
        {"treino_id": 2, "exercicio_id": 14, "ordem": 2, "series": 3, "repeticoes": 12},
        {"treino_id": 2, "exercicio_id": 28, "ordem": 3, "series": 3, "repeticoes": 15},
        # Treino 3 (Intermediário Full Body IA)
        {"treino_id": 3, "exercicio_id": 1, "ordem": 1, "series": 4, "repeticoes": 10},
        {"treino_id": 3, "exercicio_id": 2, "ordem": 2, "series": 4, "repeticoes": 12},
        {"treino_id": 3, "exercicio_id": 3, "ordem": 3, "series": 4, "repeticoes": 10},
        {"treino_id": 3, "exercicio_id": 8, "ordem": 4, "series": 3, "repeticoes": 12},
        # Treino 4 (Avançado Hipertrofia & Força Total IA)
        {"treino_id": 4, "exercicio_id": 2, "ordem": 1, "series": 4, "repeticoes": 15},
        {"treino_id": 4, "exercicio_id": 1, "ordem": 2, "series": 4, "repeticoes": 12},
        {"treino_id": 4, "exercicio_id": 3, "ordem": 3, "series": 4, "repeticoes": 12},
        {"treino_id": 4, "exercicio_id": 18, "ordem": 4, "series": 4, "repeticoes": 12},
        {"treino_id": 4, "exercicio_id": 24, "ordem": 5, "series": 4, "repeticoes": 15},
    ]

    print("\nVinculando exercícios aos treinos em 'treino_exercicios'...")
    for rel in relacoes:
        try:
            supabase.table("treino_exercicios").insert(rel).execute()
        except Exception as e:
            print(f"  [!] Erro na relação treino #{rel['treino_id']} - exercicio #{rel['exercicio_id']}: {e}")

    print("\n==================================================")
    print("✓ Reset e povoamento concluídos com sucesso!")
    print("==================================================")

if __name__ == "__main__":
    popular_banco()
