# Guia da API REST (FastAPI): Python & Flutter
**Projeto:** Personal Trainer IA — Engenharia de Software

Este documento serve como um guia prático para utilizar todos os endpoints da API FastAPI (localizada em [`BD/api.py`](BD/api.py)), contendo exemplos completos de consumo tanto em **Python** (utilizando a biblioteca `requests`) quanto em **Flutter** (utilizando o serviço [`ApiService`](lib/services/api_service.dart)).

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
* **O que faz:** Retorna os dados da tabela `usuarios` vinculados ao ID do usuário, incluindo pontuações, sequência, maior sequência e status de checagem.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  usuario_id = "uuid-do-usuario"
  res = requests.get(f"http://127.0.0.1:8000/perfil/{usuario_id}").json()
  if res["sucesso"]:
      print("Nome:", res["perfil"]["nome"])
      print("Sequência:", res["perfil"].get("sequencia"), "dias")
      print("Maior Sequência:", res["perfil"].get("maior_sequencia"), "dias")
      print("Checagem:", res["perfil"].get("checagem"))
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().verPerfil(usuarioId);
  if (resposta['sucesso'] == true) {
    print('Nome: ${resposta['perfil']['nome']}');
    print('Sequência: ${resposta['perfil']['sequencia']} dias');
    print('Maior Sequência: ${resposta['perfil']['maior_sequencia']} dias');
    print('Checagem: ${resposta['perfil']['checagem']}');
  }
  ```

---

### 2.2. Editar Perfil (`PUT /perfil/{usuario_id}`)
* **O que faz:** Atualiza os dados de nome, CPF, sequência, maior sequência e/ou checagem do usuário no banco.
* **Payload JSON:**
  ```json
  {
    "nome": "João Pedro Silva",
    "cpf": "123.456.789-00",
    "sequencia": 5,
    "maior_sequencia": 8,
    "checagem": true
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  usuario_id = "uuid-do-usuario"
  res = requests.put(f"http://127.0.0.1:8000/perfil/{usuario_id}", json={
      "nome": "João Pedro Silva",
      "cpf": "123.456.789-00",
      "sequencia": 5,
      "maior_sequencia": 8,
      "checagem": True
  }).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().editarPerfil(
    usuarioId,
    nome: 'João Pedro Silva',
    cpf: '123.456.789-00',
    sequencia: 5,
    maiorSequencia: 8,
    checagem: true,
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

### 4.2. Obter Treinos Padrão por Dificuldade (`GET /treinos/dificuldade/{dificuldade}`)
* **O que faz:** Retorna os treinos padrão categorizados para cada nível de dificuldade: `"iniciante"`, `"intermediario"` ou `"avancado"`.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  dificuldade = "iniciante"
  res = requests.get(f"http://127.0.0.1:8000/treinos/dificuldade/{dificuldade}").json()
  if res["sucesso"]:
      print(f"Treinos encontrados para {dificuldade}: {len(res['treinos'])}")
      for t in res["treinos"]:
          print(f"- {t['titulo']} (+{t['pontosTotais']} pts, {t['duracaoMinutos']} min)")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().obterTreinosPorDificuldade('iniciante');
  if (resposta['sucesso'] == true) {
    final treinos = resposta['treinos'] as List;
    print('Treinos encontrados: ${treinos.length}');
  }
  ```

---

### 4.3. Listar Treinos do Usuário (`GET /treinos/usuario/{usuario_id}`)
* **O que faz:** Retorna todos os treinos personalizados criados por um usuário (ou do usuário logado se omitido na `ApiService`).
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
  // Se omitido o ID, busca automaticamente pelo usuário logado
  final resposta = await ApiService().listarTreinosUsuario();
  if (resposta['sucesso'] == true) {
    final lista = resposta['treinos'] as List;
    print('Meus treinos: ${lista.length}');
  }
  ```

---

### 4.4. Criar Treino (`POST /treinos`)
* **O que faz:** Cria um novo treino e vincula seus exercícios com ordem, séries, repetições e pontuações calculadas.
* **Payload JSON:**
  ```json
  {
    "usuario_id": "uuid-do-usuario (opcional se logado)",
    "nome": "Treino Hipertrofia B",
    "descricao": "Membros inferiores",
    "pre_montado": false,
    "dificuldade": "Personalizado",
    "duracao_minutos": 30,
    "pontos_totais": 250,
    "exercicios": [
      {
        "exercicio_id": "1",
        "nome": "Supino Reto",
        "grupo_muscular": "Peitoral",
        "series": 4,
        "repeticoes": 10,
        "pontos_series": 200,
        "pontos_repeticoes": 200,
        "pontos_totais": 400
      }
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
      "dificuldade": "Personalizado",
      "duracao_minutos": 30,
      "pontos_totais": 400,
      "exercicios": [
          {"exercicio_id": 1, "ordem": 1, "series": 4, "repeticoes": 10}
      ]
  }
  res = requests.post("http://127.0.0.1:8000/treinos", json=payload).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService` e `ExercicioTreino`):**
  ```dart
  final exerciciosJson = exerciciosTreino.map((ex) => ex.toJson()).toList();

  final resposta = await ApiService().criarTreino(
    nome: 'Treino Hipertrofia B',
    descricao: 'Treino personalizado',
    dificuldade: 'Personalizado',
    duracaoMinutos: 35,
    pontosTotais: 400,
    exercicios: exerciciosJson,
  );
  print(resposta['mensagem']);
  ```

---

### 4.5. Editar Treino (`PUT /treinos/{treino_id}`)
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

### 4.6. Excluir Treino (`DELETE /treinos/{treino_id}`)
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
* **O que faz:** Retorna a pontuação diária, semanal e total, além da sequência de dias de uso e status de checagem do usuário.
* **Exemplo em Python (`requests`):**
  ```python
  import requests
  usuario_id = "uuid-do-usuario"
  res = requests.get(f"http://127.0.0.1:8000/pontuacao/{usuario_id}").json()
  if res["sucesso"]:
      print("Pontos Hoje:", res["pontuacao_diaria"])
      print("Pontos Semana:", res["pontuacao_semanal"])
      print("Pontos Totais:", res["pontuacao_total"])
      print("Sequência:", res["sequencia"], "dias")
      print("Checagem:", res["checagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().verPontuacao(usuarioId);
  if (resposta['sucesso'] == true) {
    print('Pontos hoje: ${resposta['pontuacao_diaria']}');
    print('Pontos semana: ${resposta['pontuacao_semanal']}');
    print('Pontos totais: ${resposta['pontuacao_total']}');
    print('Sequência: ${resposta['sequencia']} dias');
    print('Checagem ativa: ${resposta['checagem']}');
  }
  ```

---

### 5.2. Adicionar Pontuação Diária (`POST /pontuacao/diaria`)
* **O que faz:** Adiciona pontos diários ao usuário, incrementa simultaneamente a pontuação semanal e a total, define `checagem = True` e atualiza a `sequencia` de dias.
* **Payload JSON:**
  ```json
  {
    "usuario_id": "uuid-do-usuario",
    "pontos": 50,
    "incrementar_sequencia": null
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
      print(f"Sequência atual: {res['sequencia']} dias")
      print(f"Checagem: {res['checagem']}")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().adicionarPontuacaoDiaria(
    usuarioId: usuarioId,
    pontos: 50,
  );
  if (resposta['sucesso'] == true) {
    print('Pontos adicionados: ${resposta['mensagem']}');
    print('Nova sequência: ${resposta['sequencia']} dias');
  }
  ```

---

### 5.3. Atualizar Sequência (`PUT /pontuacao/{usuario_id}/sequencia` ou `POST /pontuacao/sequencia`)
* **O que faz:** Atualiza diretamente o valor numérico de dias consecutivos que a pessoa usou o app.
* **Payload JSON (`POST /pontuacao/sequencia`):**
  ```json
  {
    "usuario_id": "uuid-do-usuario",
    "sequencia": 7
  }
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().atualizarSequencia(
    usuarioId: usuarioId,
    sequencia: 7,
  );
  print(resposta['mensagem']);
  ```

---

### 5.4. Atualizar / Resetar Checagem Diária (`POST /pontuacao/{usuario_id}/resetar-checagem`)
* **O que faz:** Reseta o estado booleano de `checagem` para `false` no início de um novo dia/ciclo.
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final resposta = await ApiService().resetarChecagem(usuarioId);
  print(resposta['mensagem']);
  ```


---

## 6. 👥 Sistema de Amizades

### 6.1. Buscar Usuários (`GET /amigos/buscar`)
* **O que faz:** Realiza busca de usuários cadastrados por aproximação de nome. Ignora RLS através de RPC `SECURITY DEFINER` e identifica se já existe amizade ou solicitação pendente com o usuário atual.
* **Query Parameters:**
  * `nome` (obrigatório, string): Termo de busca (ex: `"João"` ou `"Davi"`).
  * `usuario_id` (opcional, string): ID do usuário autenticado para mapear relações e excluir o próprio perfil dos resultados.
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "usuarios": [
      {
        "id": "uuid-do-amigo",
        "nome": "João Silva",
        "sequencia": 5,
        "pontuacao_semanal": 350,
        "pontuacao_total": 1200,
        "maior_sequencia": 8,
        "relacao_status": null,
        "ja_amigo": false,
        "solicitacao_enviada": false,
        "solicitacao_recebida": false
      }
    ]
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  params = {
      "nome": "Arthur",
      "usuario_id": "uuid-meu-usuario"
  }
  res = requests.get("http://127.0.0.1:8000/amigos/buscar", params=params).json()
  if res["sucesso"]:
      for u in res["usuarios"]:
          print(f"Nome: {u['nome']} | Streak: {u['sequencia']}d | Pontos: {u['pontuacao_semanal']} | Amigo? {u['ja_amigo']}")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().buscarUsuarios('Arthur');
  if (res['sucesso'] == true) {
    final List usuarios = res['usuarios'] ?? [];
    for (var u in usuarios) {
      print('Encontrado: ${u['nome']} - ${u['pontuacao_semanal']} pts');
    }
  }
  ```

---

### 6.2. Enviar Solicitação de Amizade (`POST /amigos/solicitar`)
* **O que faz:** Cria uma solicitação de amizade na tabela `amizades` com status `"pendente"`. Impede auto-solicitação e duplicidade.
* **Payload JSON:**
  ```json
  {
    "usuario_id": "uuid-solicitante",
    "amigo_id": "uuid-destinatario"
  }
  ```
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "mensagem": "Solicitação de amizade enviada com sucesso!",
    "solicitacao": {
      "id": "uuid-da-solicitacao",
      "usuario_id": "uuid-solicitante",
      "amigo_id": "uuid-destinatario",
      "status": "pendente"
    }
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  payload = {
      "usuario_id": "uuid-meu-usuario",
      "amigo_id": "uuid-do-amigo"
  }
  res = requests.post("http://127.0.0.1:8000/amigos/solicitar", json=payload).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().enviarSolicitacaoAmizade('uuid-do-amigo');
  if (res['sucesso'] == true) {
    print('Pedido enviado!');
  } else {
    print('Erro: ${res['mensagem']}');
  }
  ```

---

### 6.3. Listar Solicitações Pendentes (`GET /amigos/solicitacoes/pendentes`)
* **O que faz:** Retorna os convites de amizade pendentes recebidos pelo usuário com o nome real e métricas de quem enviou.
* **Query Parameters:**
  * `usuario_id` (obrigatório, string): ID do usuário destinatário.
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "solicitacoes": [
      {
        "id": "uuid-solicitacao",
        "solicitante_id": "uuid-remetente",
        "nome": "Arthur Peixoto",
        "sequencia": 4,
        "pontos": 250,
        "created_at": "2026-10-24T12:00:00"
      }
    ]
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  res = requests.get("http://127.0.0.1:8000/amigos/solicitacoes/pendentes?usuario_id=uuid-meu-usuario").json()
  if res["sucesso"]:
      for pedido in res["solicitacoes"]:
          print(f"Pedido de: {pedido['nome']} (ID Pedido: {pedido['id']})")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().listarSolicitacoesPendentes();
  if (res['sucesso'] == true) {
    final pedidos = res['solicitacoes'] as List;
    print('Total de convites recebidos: ${pedidos.length}');
  }
  ```

---

### 6.4. Responder Solicitação de Amizade (`PATCH /amigos/solicitacoes/{solicitacao_id}`)
* **O que faz:** Aceita (`"aceito"`) ou recusa (`"recusado"`) um convite de amizade.
* **Path Parameter:**
  * `solicitacao_id`: UUID do registro de amizade.
* **Payload JSON:**
  ```json
  {
    "status": "aceito"
  }
  ```
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "mensagem": "Solicitação aceita! Agora vocês são amigos.",
    "dados": {
      "id": "uuid-solicitacao",
      "status": "aceito"
    }
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  solicitacao_id = "uuid-solicitacao"
  res = requests.patch(f"http://127.0.0.1:8000/amigos/solicitacoes/{solicitacao_id}", json={"status": "aceito"}).json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().responderSolicitacao('uuid-solicitacao', 'aceito');
  if (res['sucesso'] == true) {
    print('Amizade confirmada!');
  }
  ```

---

### 6.5. Listar Amigos Confirmados (`GET /amigos/`)
* **O que faz:** Retorna a lista de amigos com status `"aceito"` do usuário, trazendo nomes reais, streaks e pontuações semanais.
* **Query Parameters:**
  * `usuario_id` (obrigatório, string): ID do usuário.
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "amigos": [
      {
        "amizade_id": "uuid-amizade",
        "id": "uuid-do-amigo",
        "nome": "Arthur Peixoto",
        "sequencia": 4,
        "pontos": 250
      }
    ]
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  res = requests.get("http://127.0.0.1:8000/amigos/?usuario_id=uuid-meu-usuario").json()
  if res["sucesso"]:
      for amigo in res["amigos"]:
          print(f"Amigo: {amigo['nome']} | Sequência: {amigo['sequencia']} dias | Pontos: {amigo['pontos']} pts")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().listarAmigos();
  if (res['sucesso'] == true) {
    final amigos = res['amigos'] as List;
    print('Meus amigos: ${amigos.length}');
  }
  ```

---

### 6.6. Remover Amigo (`DELETE /amigos/{amigo_id}`)
* **O que faz:** Remove o vínculo de amizade entre o usuário autenticado e o amigo indicado.
* **Path Parameter:**
  * `amigo_id`: UUID do amigo a ser desvinculado.
* **Query Parameters:**
  * `usuario_id` (obrigatório, string): ID do usuário autenticado.
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "mensagem": "Amizade removida com sucesso!"
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  res = requests.delete("http://127.0.0.1:8000/amigos/uuid-do-amigo?usuario_id=uuid-meu-usuario").json()
  print(res["mensagem"])
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().removerAmigo('uuid-do-amigo');
  print(res['mensagem']);
  ```

---

## 7. 🏆 Sistema de Leaderboard (Rankings)

### 7.1. Leaderboard Global (`GET /leaderboard/global`)
* **O que faz:** Retorna o ranking global dos usuários ordenados decrescentemente por pontuação semanal e streak de treinos, contornando RLS via RPC `SECURITY DEFINER`.
* **Query Parameters:**
  * `limite` (opcional, inteiro de 1 a 200, padrão: 50): Quantidade máxima de registros.
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "leaderboard": [
      {
        "posicao": 1,
        "id": "uuid-1",
        "nome": "Arthur Peixoto",
        "pontos": 450,
        "sequencia": 12,
        "maior_sequencia": 15
      },
      {
        "posicao": 2,
        "id": "uuid-2",
        "nome": "Davi Lima",
        "pontos": 350,
        "sequencia": 8,
        "maior_sequencia": 10
      }
    ]
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  res = requests.get("http://127.0.0.1:8000/leaderboard/global?limite=10").json()
  if res["sucesso"]:
      print("=== TOP 10 GLOBAL ===")
      for u in res["leaderboard"]:
          print(f"#{u['posicao']} {u['nome']} - {u['pontos']} pts | {u['sequencia']} dias streak")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().obterLeaderboardGlobal(limite: 20);
  if (res['sucesso'] == true) {
    final ranking = res['leaderboard'] as List;
    print('Total ranqueados: ${ranking.length}');
  }
  ```

---

### 7.2. Leaderboard de Amigos (`GET /leaderboard/amigos`)
* **O que faz:** Retorna o ranking restrito ao usuário logado e seus amigos aceitos, ordenado por pontos e streak. Inclui a flag `is_me` para destacar o usuário na listagem.
* **Query Parameters:**
  * `usuario_id` (obrigatório, string): ID do usuário.
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "leaderboard": [
      {
        "posicao": 1,
        "id": "uuid-amigo",
        "nome": "Arthur Peixoto",
        "pontos": 450,
        "sequencia": 12,
        "maior_sequencia": 15,
        "is_me": false
      },
      {
        "posicao": 2,
        "id": "uuid-meu-usuario",
        "nome": "Davi Lima",
        "pontos": 350,
        "sequencia": 8,
        "maior_sequencia": 10,
        "is_me": true
      }
    ]
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  res = requests.get("http://127.0.0.1:8000/leaderboard/amigos?usuario_id=uuid-meu-usuario").json()
  if res["sucesso"]:
      print("=== RANKING ENTRE AMIGOS ===")
      for u in res["leaderboard"]:
          destaque = " (VOCÊ)" if u.get("is_me") else ""
          print(f"#{u['posicao']} {u['nome']}{destaque}: {u['pontos']} pts ({u['sequencia']}d)")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().obterLeaderboardAmigos();
  if (res['sucesso'] == true) {
    final rankingAmigos = res['leaderboard'] as List;
    print('Ranqueados no círculo de amigos: ${rankingAmigos.length}');
  }
  ```

---

### 7.3. Minha Posição no Ranking Global (`GET /leaderboard/minha-posicao`)
* **O que faz:** Retorna a posição ordinal exata do usuário logado no ranking global com base na pontuação semanal.
* **Query Parameters:**
  * `usuario_id` (obrigatório, string): ID do usuário.
* **Retorno de Sucesso:**
  ```json
  {
    "sucesso": true,
    "posicao": 2
  }
  ```
* **Exemplo em Python (`requests`):**
  ```python
  import requests

  res = requests.get("http://127.0.0.1:8000/leaderboard/minha-posicao?usuario_id=uuid-meu-usuario").json()
  if res["sucesso"]:
      print(f"Minha posição atual no mundo: #{res['posicao']}")
  ```
* **Exemplo em Flutter (`ApiService`):**
  ```dart
  final res = await ApiService().obterMinhaPosicaoGlobal();
  if (res['sucesso'] == true) {
    print('Sua posição: #${res['posicao']}');
  }
  ```
