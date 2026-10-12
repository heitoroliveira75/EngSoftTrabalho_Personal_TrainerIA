import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import joblib

def treinar_e_salvar_modelo():
    # 1. Base de Dados
    # Para o teste inicial, criamos dados simulados (mock data).
    # Posteriormente, substitua isso pela leitura de um CSV gerado a partir do dataset FIT3D.
    # Exemplo futuro: df = pd.read_csv("meu_dataset_treino.csv")
    dados = {
        "cotovelo_min": [45.0, 42.1, 48.0, 80.5, 90.0, 85.3, 100.0],
        "cotovelo_max": [170.0, 165.5, 175.0, 120.0, 110.5, 130.0, 105.0],
        "ombro_variacao": [20.0, 18.5, 22.1, 45.0, 50.0, 40.0, 60.0],
        "veredito": [1, 1, 1, 0, 0, 0, 0]  # 1 = CORRETO, 0 = INCORRETO
    }
    df = pd.DataFrame(dados)

    # 2. Separação de Características (Features) e Alvo (Target)
    # A ordem das colunas DEVE ser idêntica à lista passada no predict() do Modularização.py
    X = df[["cotovelo_min", "cotovelo_max", "ombro_variacao"]]
    y = df["veredito"]

    # 3. Divisão entre dados de treino e dados de teste
    X_treino, X_teste, y_treino, y_teste = train_test_split(X, y, test_size=0.2, random_state=42)

    # 4. Criação e Treinamento do Modelo (Random Forest)
    print("Treinando o modelo de Inteligência Artificial...")
    modelo = RandomForestClassifier(n_estimators=100, random_state=42)
    modelo.fit(X_treino, y_treino)

    # 5. Avaliação de Precisão
    predicoes = modelo.predict(X_teste)
    precisao = accuracy_score(y_teste, predicoes)
    print(f"Precisão do modelo validada em: {precisao * 100:.2f}%")

    # 6. Exportação do Arquivo .pkl
    nome_arquivo = "meu_personal_trainer_ia.pkl"
    joblib.dump(modelo, nome_arquivo)
    print(f"Sucesso! Modelo salvo como '{nome_arquivo}'.")

if __name__ == "__main__":
    treinar_e_salvar_modelo()