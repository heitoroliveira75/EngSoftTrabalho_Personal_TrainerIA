# Guia da API REST (FastAPI): Python & Flutter
**Projeto:** Personal Trainer IA — Engenharia de Software

Este documento serve como um guia prático para utilizar todos os endpoints da API FastAPI (localizada em [`BD/api.py`](file:///C:/Users/davil/Documents/EngSoftTrabalho_Personal_TrainerIA/BD/api.py)), contendo exemplos completos de consumo tanto em **Python** (utilizando a biblioteca `requests`) quanto em **Flutter** (utilizando o serviço [`ApiService`](file:///C:/Users/davil/Documents/EngSoftTrabalho_Personal_TrainerIA/lib/services/api_service.dart)).

---

## 🚀 Como Iniciar o Servidor da API

1. Abra um terminal na pasta `BD`:
   ```powershell
   cd BD
   ```

2. Execute o servidor FastAPI:
   ```powershell
   python api.py
   # ou
   uvicorn api:app --host 0.0.0.0 --port 8000 --reload
   ```

3. **URLs de Acesso:**
   * **Swagger / Documentação Interativa:** [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
   * **Redoc:** [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)
   * **Flutter Windows / Web / iOS Simulator:** `http://127.0.0.1:8000`
   * **Flutter Emulador Android:** `http://10.0.2.2:8000`
   * **Flutter Dispositivo Físico (Wi-Fi):** `http://<IP_DO_PC>:8000`

---

## 📋 Padrão de Resposta da API

Todas as rotas respondem no formato JSON padronizado:
```json
{
  "sucesso": true,
  "mensagem": "Operação realizada com sucesso",
  "dados": { ... }
}
```

---

## 1. 🔐 Autenticação e Sessão

### 1.1. Criar Conta (`POST /auth/criar-conta`)
* **O que faz:** Registra um novo usuário no Supabase Auth e insere na tabela `usuarios`.
* **Payload JSON:**
  ```json
  {
    "nome": "João Silva",
    "email": "joao@email.com",
    "senha": "senhaSegura123"
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  payload = {
      "nome": "João Silva",
      "email": "joao@email.com",
      "senha": "senhaSegura123"
  }
  res = requests.post("http://127.0.0.1:8000/auth/criar-conta", json=payload).json()
  if res["sucesso"]:
      print("Conta criada com sucesso! ID:", res["usuario"]["id"])
  else:
      print("Erro:", res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().criarConta(
    nome: 'João Silva',
    email: 'joao@email.com',
    senha: 'senhaSegura123',
  );

  if (resposta['sucesso'] == true) {
    print('Conta criada: ${resposta['usuario']}');
  } else {
    print('Erro: ${resposta['mensagem']}');
  }
  ```

---

### 1.2. Fazer Login (`POST /auth/login`)
* **O que faz:** Autentica o usuário com e-mail e senha, retornando token JWT e dados do perfil.
* **Payload JSON:**
  ```json
  {
    "email": "joao@email.com",
    "senha": "senhaSegura123"
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  res = requests.post("http://127.0.0.1:8000/auth/login", json={
      "email": "joao@email.com",
      "senha": "senhaSegura123"
  }).json()

  if res["sucesso"]:
      token = res["sessao"]["access_token"]
      print("Login com sucesso! Token:", token)
  else:
      print("Falha:", res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().fazerLogin(
    email: 'joao@email.com',
    senha: 'senhaSegura123',
  );

  if (resposta['sucesso'] == true) {
    print('Bem-vindo, ${ApiService().nomeUsuarioAtual}!');
  } else {
    print('Erro: ${resposta['mensagem']}');
  }
  ```

---

### 1.3. Deslogar (`POST /auth/logout`)
* **O que faz:** Encerra a sessão ativa do usuário no Supabase.
* **Payload JSON:** Nenhum (vazio).
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  res = requests.post("http://127.0.0.1:8000/auth/logout").json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().deslogar();
  print(resposta['mensagem']);
  ```

---

### 1.4. Obter Usuário Atual (`GET /auth/usuario-atual`)
* **O que faz:** Retorna as informações do usuário atualmente autenticado.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  res = requests.get("http://127.0.0.1:8000/auth/usuario-atual").json()
  if res["sucesso"]:
      print("Usuário autenticado:", res["usuario"]["email"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().obterUsuarioAtual();
  if (resposta['sucesso'] == true) {
    print('Usuário atual: ${resposta['usuario']['email']}');
  }
  ```

---

### 1.5. Solicitar Recuperação de Senha (`POST /auth/esqueceu-senha`)
* **O que faz:** Dispara um e-mail de recuperação pelo Supabase Auth com código/link OTP.
* **Payload JSON:**
  ```json
  {
    "email": "joao@email.com"
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  res = requests.post("http://127.0.0.1:8000/auth/esqueceu-senha", json={"email": "joao@email.com"}).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().esqueceuSenha(email: 'joao@email.com');
  print(resposta['mensagem']);
  ```

---

### 1.6. Redefinir Senha com Código (`POST /auth/redefinir-senha`)
* **O que faz:** Valida o código OTP recebido por e-mail e aplica a nova senha.
* **Payload JSON:**
  ```json
  {
    "email": "joao@email.com",
    "codigo": "123456",
    "nova_senha": "novaSenhaSegura456"
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  res = requests.post("http://127.0.0.1:8000/auth/redefinir-senha", json={
      "email": "joao@email.com",
      "codigo": "123456",
      "nova_senha": "novaSenhaSegura456"
  }).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().redefinirSenha(
    email: 'joao@email.com',
    codigo: '123456',
    novaSenha: 'novaSenhaSegura456',
  );
  print(resposta['mensagem']);
  ```

---

### 1.7. Alterar Senha Logado (`POST /auth/alterar-senha`)
* **O que faz:** Valida a senha atual do usuário autenticado e a atualiza para a nova senha.
* **Payload JSON:**
  ```json
  {
    "senha_atual": "senhaAntiga123",
    "nova_senha": "novaSenhaSegura456",
    "email": "joao@email.com"
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  res = requests.post("http://127.0.0.1:8000/auth/alterar-senha", json={
      "senha_atual": "senhaAntiga123",
      "nova_senha": "novaSenhaSegura456",
      "email": "joao@email.com"
  }).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().alterarSenha(
    senhaAtual: 'senhaAntiga123',
    novaSenha: 'novaSenhaSegura456',
    email: 'joao@email.com',
  );
  print(resposta['mensagem']);
  ```

---

## 2. 👤 Perfil de Usuário

### 2.1. Visualizar Perfil (`GET /perfil/{usuario_id}`)
* **O que faz:** Retorna os dados da tabela `usuarios` vinculados ao ID do usuário.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  usuario_id = "uuid-do-usuario"
  res = requests.get(f"http://127.0.0.1:8000/perfil/{usuario_id}").json()
  if res["sucesso"]:
      print("Nome:", res["perfil"]["nome"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().verPerfil(usuarioId);
  if (resposta['sucesso'] == true) {
    print('Nome: ${resposta['perfil']['nome']}');
  }
  ```

---

### 2.2. Editar Perfil (`PUT /perfil/{usuario_id}`)
* **O que faz:** Atualiza os dados de nome e/ou CPF do usuário no banco.
* **Payload JSON:**
  ```json
  {
    "nome": "João Pedro Silva",
    "cpf": "123.456.789-00"
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  usuario_id = "uuid-do-usuario"
  res = requests.put(f"http://127.0.0.1:8000/perfil/{usuario_id}", json={
      "nome": "João Pedro Silva",
      "cpf": "123.456.789-00"
  }).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().editarPerfil(
    usuarioId,
    nome: 'João Pedro Silva',
    cpf: '123.456.789-00',
  );
  print(resposta['mensagem']);
  ```

---

## 3. 🏋️ Exercícios

### 3.1. Listar Exercícios (`GET /exercicios`)
* **O que faz:** Retorna todos os exercícios cadastrados ou filtrados por grupo muscular.
* **Query Params:** `grupo_muscular` (opcional: ex: "Peito", "Costas", "Pernas").
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  res = requests.get("http://127.0.0.1:8000/exercicios", params={"grupo_muscular": "Peito"}).json()
  if res["sucesso"]:
      for ex in res["exercicios"]:
          print(f"- {ex['nome']} ({ex['grupo_muscular']})")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().listarExercicios(grupoMuscular: 'Peito');
  if (resposta['sucesso'] == true) {
    final exercicios = resposta['exercicios'] as List;
    for (var ex in exercicios) {
      print('- ${ex['nome']}');
    }
  }
  ```

---

## 4. 📋 Treinos

### 4.1. Ver Treinos Pré-Montados (`GET /treinos/pre-montados`)
* **O que faz:** Lista todos os treinos pré-montados com seus exercícios associados.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  res = requests.get("http://127.0.0.1:8000/treinos/pre-montados").json()
  if res["sucesso"]:
      print(f"Total de treinos padrões: {len(res['treinos'])}")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().verTreinosPremontados();
  if (resposta['sucesso'] == true) {
    final lista = resposta['treinos'] as List;
    print('Treinos pré-montados: ${lista.length}');
  }
  ```

---

### 4.2. Listar Treinos do Usuário (`GET /treinos/usuario/{usuario_id}`)
* **O que faz:** Retorna todos os treinos personalizados criados por um usuário.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  usuario_id = "uuid-do-usuario"
  res = requests.get(f"http://127.0.0.1:8000/treinos/usuario/{usuario_id}").json()
  if res["sucesso"]:
      print(f"Treinos do usuário: {len(res['treinos'])}")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().listarTreinosUsuario(usuarioId);
  if (resposta['sucesso'] == true) {
    final lista = resposta['treinos'] as List;
    print('Meus treinos: ${lista.length}');
  }
  ```

---

### 4.3. Criar Treino (`POST /treinos`)
* **O que faz:** Cria um novo treino e vincula seus exercícios com ordem, séries e repetições.
* **Payload JSON:**
  ```json
  {
    "usuario_id": "uuid-do-usuario",
    "nome": "Treino Hipertrofia B",
    "descricao": "Membros inferiores",
    "pre_montado": false,
    "exercicios": [
      { "exercicio_id": 1, "ordem": 1, "series": 4, "repeticoes": 12 },
      { "exercicio_id": 2, "ordem": 2, "series": 3, "repeticoes": 15 }
    ]
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  payload = {
      "usuario_id": "uuid-do-usuario",
      "nome": "Treino Hipertrofia B",
      "descricao": "Membros inferiores",
      "pre_montado": False,
      "exercicios": [
          {"exercicio_id": 1, "ordem": 1, "series": 4, "repeticoes": 12},
          {"exercicio_id": 2, "ordem": 2, "series": 3, "repeticoes": 15}
      ]
  }
  res = requests.post("http://127.0.0.1:8000/treinos", json=payload).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().criarTreino(
    usuarioId: usuarioId,
    nome: 'Treino Hipertrofia B',
    descricao: 'Membros inferiores',
    exercicios: [
      {'exercicio_id': 1, 'ordem': 1, 'series': 4, 'repeticoes': 12},
      {'exercicio_id': 2, 'ordem': 2, 'series': 3, 'repeticoes': 15},
    ],
  );
  print(resposta['mensagem']);
  ```

---

### 4.4. Editar Treino (`PUT /treinos/{treino_id}`)
* **O que faz:** Atualiza os dados de nome, descrição ou lista de exercícios vinculados.
* **Payload JSON:**
  ```json
  {
    "nome": "Treino Hipertrofia B - Atualizado",
    "descricao": "Nova descrição do treino"
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  treino_id = 1
  res = requests.put(f"http://127.0.0.1:8000/treinos/{treino_id}", json={
      "nome": "Treino Hipertrofia B - Atualizado"
  }).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().editarTreino(
    treinoId,
    nome: 'Treino Hipertrofia B - Atualizado',
  );
  print(resposta['mensagem']);
  ```

---

### 4.5. Excluir Treino (`DELETE /treinos/{treino_id}`)
* **O que faz:** Remove o treino e desvincula os exercícios associados.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  treino_id = 1
  res = requests.delete(f"http://127.0.0.1:8000/treinos/{treino_id}").json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().excluirTreino(treinoId);
  print(resposta['mensagem']);
  ```

---

## 5. 🏆 Pontuações e Gamificação

### 5.1. Visualizar Pontuações (`GET /pontuacao/{usuario_id}`)
* **O que faz:** Retorna a pontuação diária, semanal e total do usuário armazenada na tabela `usuarios`.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  usuario_id = "uuid-do-usuario"
  res = requests.get(f"http://127.0.0.1:8000/pontuacao/{usuario_id}").json()
  if res["sucesso"]:
      print("Pontos Hoje:", res["pontuacao_diaria"])
      print("Pontos Semana:", res["pontuacao_semanal"])
      print("Pontos Totais:", res["pontuacao_total"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().verPontuacao(usuarioId);
  if (resposta['sucesso'] == true) {
    print('Pontos hoje: ${resposta['pontuacao_diaria']}');
    print('Pontos semana: ${resposta['pontuacao_semanal']}');
    print('Pontos totais: ${resposta['pontuacao_total']}');
  }
  ```

---

### 5.2. Adicionar Pontuação Diária (`POST /pontuacao/diaria`)
* **O que faz:** Adiciona pontos diários ao usuário e incrementa simultaneamente a pontuação semanal e a pontuação total.
* **Payload JSON:**
  ```json
  {
    "usuario_id": "uuid-do-usuario",
    "pontos": 50
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  payload = {
      "usuario_id": "uuid-do-usuario",
      "pontos": 50
  }
  res = requests.post("http://127.0.0.1:8000/pontuacao/diaria", json=payload).json()
  if res["sucesso"]:
      print(res["mensagem"])
      print(f"Nova pontuação hoje: {res['pontuacao_diaria']} pts")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().adicionarPontuacaoDiaria(
    usuarioId: usuarioId,
    pontos: 50,
  );
  if (resposta['sucesso'] == true) {
    print('Pontos adicionados: ${resposta['mensagem']}');
  }
  ```

