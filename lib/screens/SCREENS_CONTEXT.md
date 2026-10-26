# 📱 Guia de Contexto de Telas (UI): Personal Trainer IA

> **Última Atualização:** 2026-10-24  
> **Camada:** Front-end (Flutter / Dart)  
> **Status:** Ativo / Consolidado  

---

## 1. 📖 Visão Geral da Interface

A camada visual do aplicativo **Personal Trainer IA** é desenvolvida em **Flutter**, utilizando o padrão de design escuro (*Dark Theme*) moderno com detalhes em verde neon, voltado para foco e alto contraste em ambientes de treino.

A navegação é predominantemente estruturada em **Rotas Nomeadas** centralizadas em [`lib/main.dart`](lib/main.dart), combinada com navegações dinâmicas com passagem de argumentos via `MaterialPageRoute` quando é necessário transitar dados complexos (como o objeto completo do treino selecionado ou retorno com refresh de listas).

---

## 2. 🗺️ Mapa e Fluxo de Navegação

```mermaid
flowchart TD
    subgraph AuthModule["Módulo de Autenticação"]
        Login["/login\n(login_screen.dart)"]
        Cadastro["/cadastro\n(cadastro_screen.dart)"]
        Esqueceu["/esqueceu-senha\n(esqueceu_senha_screen.dart)"]
        Redefinir["/redefinir-senha\n(redefinir_senha_screen.dart)"]

        Login <--> Cadastro
        Login --> Esqueceu --> Redefinir --> Login
    end

    subgraph MainApp["Ambiente Autenticado"]
        Home["/home\n(home_screen.dart)"]
        Perfil["/perfil\n(profile_screen.dart)"]
        AltNome["/alterar-nome\n(change_name_screen.dart)"]
        AltSenha["/alterar-senha\n(change_password_screen.dart)"]
        Leaderboard["/leaderboard\n(leaderboard_screen.dart)"]
        Amigos["/amigos\n(amigos_screen.dart)"]
        
        Login -->|Login com Sucesso| Home
        Home <--> Perfil
        Home <--> Leaderboard
        Home <--> Amigos
        Perfil <--> Leaderboard
        Perfil <--> Amigos
        Leaderboard <--> Amigos
        Perfil --> AltNome
        Perfil --> AltSenha
        Perfil -->|Logout| Login
    end

    subgraph WorkoutModule["Módulo de Treinos & Exercícios"]
        MenuTreinos["/treino-menu\n(training_menu_screen.dart)"]
        Dificuldade["/dificuldade\n(dificuldade_treino_screen.dart)"]
        OpcaoTreinos["/opcao-treinos ou /meus-treinos\n(opcao_treinos_screen.dart)"]
        CriarTreino["/criar-treino\n(criar_exercicio_screen.dart)"]
        TreinoSelecionado["Treino Selecionado\n(treino_selecionado_screen.dart)"]
        TreinosCat["/treinos\n(treinos_screen.dart)"]

        Home --> MenuTreinos
        Home --> TreinosCat
        MenuTreinos --> Dificuldade --> OpcaoTreinos --> TreinoSelecionado
        MenuTreinos --> CriarTreino
        MenuTreinos -->|Meus Treinos| OpcaoTreinos
    end
```

---

## 3. 📋 Catálogo Completo de Telas

| Arquivo | Rota Nomeada | Módulo | Descrição & Responsabilidade | Integração com `ApiService` |
| :--- | :--- | :--- | :--- | :--- |
| [`login_screen.dart`](lib/screens/login_screen.dart) | `/login` | Autenticação | Tela inicial para inserção de e-mail e senha, com validação de campos e redirecionamentos. | `fazerLogin(email, senha)` |
| [`cadastro_screen.dart`](lib/screens/cadastro_screen.dart) | `/cadastro` | Autenticação | Formulário de criação de conta com nome completo, e-mail e confirmação de senha. | `criarConta(nome, email, senha)` |
| [`esqueceu_senha_screen.dart`](lib/screens/esqueceu_senha_screen.dart) | `/esqueceu-senha` | Autenticação | Solicitação de recuperação de senha; envia código OTP para o e-mail informado. | `solicitarRecuperacaoSenha(email)` |
| [`redefinir_senha_screen.dart`](lib/screens/redefinir_senha_screen.dart) | `/redefinir-senha` | Autenticação | Validação do código numérico de 6 dígitos recebido por e-mail e definição da nova senha. | `redefinirSenhaComCodigo(...)` |
| [`home_screen.dart`](lib/screens/home_screen.dart) | `/home` | Dashboard | Painel central do usuário com métricas de gamificação (pontos semanais, totais, streak atual, maior sequência e meta) e atalhos para Treinos, Leaderboard, Amigos e Perfil. | `verPontuacao(id)` |
| [`profile_screen.dart`](lib/screens/profile_screen.dart) | `/perfil` | Usuário | Exibição das informações da conta, streak acumulado, opções de segurança, acesso a amigos/ranking e botão de logout. | `verPerfil(id)`, `deslogar()` |
| [`change_name_screen.dart`](lib/screens/change_name_screen.dart) | `/alterar-nome` | Usuário | Formulário simplificado para alteração do nome de exibição do usuário na tabela `usuarios`. | `editarPerfil(id, nome: ...)` |
| [`change_password_screen.dart`](lib/screens/change_password_screen.dart) | `/alterar-senha` | Usuário | Alteração de senha quando o usuário já se encontra autenticado. | `alterarSenha(novaSenha, senhaAtual)` |
| [`leaderboard_screen.dart`](lib/screens/leaderboard_screen.dart) | `/leaderboard` | Social / Gamificação | Classificação Geral e Entre Amigos com métricas duplas (**Pontuação Semanal** e **Streak**), seletor dinâmico de critério de ordenação, pódio dos Top 3 e card individual de colocação. | `obterLeaderboardGlobal()`, `obterLeaderboardAmigos()`, `obterMinhaPosicaoGlobal()` |
| [`amigos_screen.dart`](lib/screens/amigos_screen.dart) | `/amigos` | Social | Gestão completa de amizades estruturada em 3 abas: "Meus Amigos" (lista e remoção), "Solicitações" (convites pendentes com aceitar/recusar) e "Buscar" (busca em tempo real por nome e envio de convites). | `listarAmigos()`, `listarSolicitacoesPendentes()`, `buscarUsuarios(nome)`, `enviarSolicitacaoAmizade(id)`, `responderSolicitacao(id, status)`, `removerAmigo(id)` |
| [`training_menu_screen.dart`](lib/screens/training_menu_screen.dart) | `/treino-menu` | Treinos | Hub visual de treinos: atalhos para escolher nível de dificuldade, acessar treinos salvos ou criar treino do zero. | Navegação local |
| [`dificuldade_treino_screen.dart`](lib/screens/dificuldade_treino_screen.dart) | `/dificuldade` | Treinos | Cards seletivos de intensidade: Iniciante (Verde), Intermediário (Laranja) e Avançado (Vermelho). | Navegação com passagem de flag |
| [`opcao_treinos_screen.dart`](lib/screens/opcao_treinos_screen.dart) | `/opcao-treinos` / `/meus-treinos` | Treinos | Lista os treinos correspondentes ao filtro. Carrega dados do backend com fallback para catálogo offline estruturado. | `listarTreinosPreMontados()`, `listarTreinosUsuario(id)` |
| [`treino_selecionado_screen.dart`](lib/screens/treino_selecionado_screen.dart) | *(Push Dinâmico)* | Treinos | Detalhes completos do treino: duração, pontuação esperada, lista de exercícios com séries e repetições. Permite salvar e executar o treino. | `criarTreino(...)`, `adicionarPontuacaoDiaria(...)` |
| [`criar_exercicio_screen.dart`](lib/screens/criar_exercicio_screen.dart) | `/criar-treino` | Treinos | Construtor interativo de treinos personalizados, permitindo nomear, definir séries, repetições e agrupar exercícios. | `listarExercicios()`, `criarTreino(...)` |
| [`treinos_screen.dart`](lib/screens/treinos_screen.dart) | `/treinos` | Treinos | Visualização de rotinas rápidas organizadas por categorias e grupamentos musculares. | Navegação e filtros |

---

## 4. 🎨 Padrões de Design e UI/UX

O aplicativo implementa o tema definido no `ThemeData` de [`lib/main.dart`](lib/main.dart):

| Token Visual | Valor Hexadecimal | Aplicação |
| :--- | :--- | :--- |
| **Scaffold Background** | `#0D1117` | Fundo principal de todas as telas (Dark GitHub/Terminal style). |
| **Surface / Card Background**| `#1E232A` | Fundo de containers, caixas de diálogo, cartões de treino e inputs. |
| **Primary Color** | `#00E676` | Verde neon de destaque: botões principais, status de sucesso, streaks ativos. |
| **Secondary / Accent** | `#E91E63` | Rosa/magenta para destaques secundários e badges de intensidade alta. |
| **Podium Ouro / Prata / Bronze** | `#FFD700` / `#C0C0C0` / `#CD7F32` | Pódio dos três primeiros colocados no Leaderboard. |
| **Text Primary** | `#FFFFFF` | Títulos e textos de alto contraste. |
| **Text Secondary / Muted** | `#8B949E` | Rótulos, descrições secundárias e placeholders. |

---

## 5. ⚙️ Gerenciamento de Estado & Ciclo de Vida

1. **Padrão Utilizado:** Todas as telas com dados assíncronos utilizam `StatefulWidget` com controle local de `setState`.
2. **Ciclo de Vida Assíncrono:** Em requisições HTTP dentro do `initState` ou handlers de eventos, a propriedade `mounted` é sempre verificada antes de invocar `setState`, prevenindo vazamentos de memória e erros de contexto desmontado.
3. **Debounce em Buscas:** Na tela `AmigosScreen`, o campo de texto utiliza um `Timer` de 350ms para evitar disparo de requisições excessivas enquanto o usuário está digitando o nome.
4. **Isolamento de Requisições:** Nenhuma tela importa `package:http/http.dart`; toda a comunicação com a API REST é delegada exclusivamente ao singleton `ApiService()`.
