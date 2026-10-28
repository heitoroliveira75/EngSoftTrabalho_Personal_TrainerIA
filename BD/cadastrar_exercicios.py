"""
Script para cadastrar e sincronizar os 30 exercícios do arquivo 'Exercicios.txt' no Supabase,
assegurando a compatibilidade com os novos IDs utilizados pela IA:
  - ID 16: Desenvolvimento com Halteres (Ombros)  -> IA Biomecânica
  - ID 11: Agachamento Livre (Pernas)             -> IA Biomecânica
  - ID 20: Rosca Direta (Bíceps)                  -> IA Biomecânica
"""

import os
import sys
import json
from pathlib import Path

# Adiciona o diretório BD e raiz ao path
DIRETORIO_BD = Path(__file__).resolve().parent
RAIZ_REPOSITORIO = DIRETORIO_BD.parent
if str(DIRETORIO_BD) not in sys.path:
    sys.path.insert(0, str(DIRETORIO_BD))

from supabase_client import supabase

CAMINHO_EXERCICIOS_TXT = RAIZ_REPOSITORIO / "Exercicios.txt"

def carregar_exercicios_do_arquivo():
    if not CAMINHO_EXERCICIOS_TXT.exists():
        raise FileNotFoundError(f"Arquivo não encontrado em: {CAMINHO_EXERCICIOS_TXT}")
    
    with open(CAMINHO_EXERCICIOS_TXT, "r", encoding="utf-8") as f:
        dados = json.load(f)
    return dados

def cadastrar_exercicios():
    print("=" * 60)
    print("Sincronização de Exercícios no Banco de Dados (Molde Exercicios.txt)")
    print("=" * 60)

    lista_exercicios = carregar_exercicios_do_arquivo()
    print(f"Total de exercícios encontrados no arquivo: {len(lista_exercicios)}")

    ids_ia = {11: "Pernas (Agachamento)", 16: "Ombros (Desenvolvimento)", 20: "Bíceps (Rosca Direta)"}

    sucessos = 0
    falhas = 0

    for item in lista_exercicios:
        payload = {
            "id": item["id"],
            "nome": item["nome"],
            "descricao": item.get("descricao", ""),
            "grupo_muscular": item.get("grupo_muscular", "Geral")
        }

        tag_ia = f" ⭐ [MOTOR DE IA: {ids_ia[item['id']]}]" if item["id"] in ids_ia else ""

        try:
            # Usa upsert para inserir se não existir ou atualizar mantendo o ID
            supabase.table("exercicios").upsert(payload).execute()
            print(f"  [✓] ID {payload['id']:02d}: {payload['nome']} ({payload['grupo_muscular']}){tag_ia}")
            sucessos += 1
        except Exception as e:
            print(f"  [✗] Erro no ID {payload['id']}: {e}")
            falhas += 1

    print("\n" + "=" * 60)
    print(f"Resumo da Sincronização: {sucessos} cadastrados com sucesso, {falhas} falhas.")
    print("=" * 60)
    print("\nOs IDs oficiais da IA estão ativos:")
    print("  - ID 16: Desenvolvimento com Halteres (Ombros)")
    print("  - ID 11: Agachamento Livre (Pernas)")
    print("  - ID 20: Rosca Direta (Bíceps)")

if __name__ == "__main__":
    cadastrar_exercicios()
