# 🗺️ Mapa de Instalação — Campo de Batalha / Do Chaos

Guia de **onde colocar cada script no Roblox Studio** e o que precisa ser
preparado para os sistemas funcionarem. Os scripts já estão organizados em
`src/` espelhando a árvore do Studio — é só copiar cada um para o lugar
indicado (veja o passo a passo no `README.md`).

> Lembrete da convenção: `.server.luau` = **Script**, `.client.luau` =
> **LocalScript**, `.luau` = **ModuleScript**. O nome do objeto no Studio é o
> nome do arquivo **sem o sufixo**.

---

## ✅ Sistemas pedidos e onde eles estão

| Sistema que você pediu | Arquivo(s) responsável(is) |
| ---------------------- | -------------------------- |
| Seleção de personagens (atualizado) | `CharacterSystemClient` (cliente) + `GameManager` (servidor) |
| Troca de personagem | `CharacterSystemClient` (equipar outro personagem = trocar) |
| Times | `TeamSystemServer` + `TeamMenuClient` + `TeamDamageProtection` |
| Spawn e espectador | `SpawnSystem` (servidor) + `SpectatorClient` (cliente) |
| Moedas | `CoinDrop` + `DataManager` (guarda as moedas) |
| HP (vida) | `HealthDisplay` (HUD) + vida por personagem no `GameManager`/`DataManager` |
| Anti-tool após a morte | `AntiToolSystem` |
| Administrador | `AdminSystemServer` + `AdminMenuClient` |
| Tutorial | `TutorialSystemServer` + `TutorialMenuClient` |
| Missões | `DailyRewardsServer` + `DailyRewardsClient` (as missões diárias ficam aqui) |
| Música | `MusicPlayerClient` |
| Tela de carregamento | `LoadingScreen` (criado do zero, tema retrô) |

**Base necessária** (faz tudo acima funcionar): `DataManager`,
`MainSystemInitializer`, `GlobalSync`, `ClientSync` e `UnifiedMenuClient`.

---

## 📍 Tabela de posicionamento (arquivo → Studio)

### ServerScriptService — Scripts do servidor
| Arquivo em `src/ServerScriptService/` | Objeto no Studio (Script) |
| ------------------------------------- | ------------------------- |
| `DataManager.server.luau` | `DataManager` |
| `MainSystemInitializer.server.luau` | `MainSystemInitializer` |
| `GameManager.server.luau` | `GameManager` |
| `GlobalSync.server.luau` | `GlobalSync` |
| `TeamSystemServer.server.luau` | `TeamSystemServer` |
| `TeamDamageProtection.server.luau` | `TeamDamageProtection` |
| `AntiToolSystem.server.luau` | `AntiToolSystem` |
| `SpawnSystem.server.luau` | `SpawnSystem` |
| `AdminSystemServer.server.luau` | `AdminSystemServer` |
| `TutorialSystemServer.server.luau` | `TutorialSystemServer` |
| `DailyRewardsServer.server.luau` | `DailyRewardsServer` |

### StarterPlayer → StarterPlayerScripts — LocalScripts do cliente
| Arquivo em `src/StarterPlayer/StarterPlayerScripts/` | Objeto no Studio (LocalScript) |
| ---------------------------------------------------- | ------------------------------ |
| `UnifiedMenuClient.client.luau` | `UnifiedMenuClient` |
| `CharacterSystemClient.client.luau` | `CharacterSystemClient` |
| `ClientSync.client.luau` | `ClientSync` |
| `TeamMenuClient.client.luau` | `TeamMenuClient` |
| `HealthDisplay.client.luau` | `HealthDisplay` |
| `AdminMenuClient.client.luau` | `AdminMenuClient` |
| `MusicPlayerClient.client.luau` | `MusicPlayerClient` |
| `DailyRewardsClient.client.luau` | `DailyRewardsClient` |
| `TutorialMenuClient.client.luau` | `TutorialMenuClient` |
| `SpectatorClient.client.luau` | `SpectatorClient` |

### StarterPlayer → StarterCharacterScripts
| Arquivo | Objeto no Studio (Script) |
| ------- | ------------------------- |
| `src/StarterPlayer/StarterCharacterScripts/CoinDrop.server.luau` | `CoinDrop` |

### ReplicatedFirst
| Arquivo | Objeto no Studio (LocalScript) |
| ------- | ------------------------------ |
| `src/ReplicatedFirst/LoadingScreen.client.luau` | `LoadingScreen` |

> As pastas `Remotes` e `Events` em `ReplicatedStorage` **são criadas
> automaticamente** pelo `MainSystemInitializer` quando o jogo roda — você não
> precisa criá-las à mão.

---

## 🏗️ O que você precisa montar no Studio (à mão)

Estes sistemas esperam alguns objetos/pastas no jogo. Crie-os com **exatamente
estes nomes**:

| Onde | Objeto | Tipo | Para qual sistema | Obrigatório? |
| ---- | ------ | ---- | ----------------- | ------------ |
| `Workspace` | `MapaPrincipal` | Model (o seu mapa) | SpawnSystem usa para posicionar o lobby acima do mapa | Sim |
| `Workspace` | `PlayerTp` | Folder com várias `Part` | SpawnSystem usa as Parts como pontos de spawn no mapa | Sim |
| `Workspace` | `MusicHolder` | Folder com `Sound`s | MusicPlayerClient toca essas músicas | Para música |
| `ReplicatedStorage` | `DropCash` | Model (visual da moeda) | CoinDrop clona ao morrer | Para drop de moedas |
| `ReplicatedStorage` | `Characters` | Folder (uma subpasta por personagem, com Tools) | Sistema de personagens | Sim |
| `ReplicatedStorage` | `CharacterImages` | Folder (imagens dos personagens) | Mostrar imagem na loja | Opcional |

> Dica: o `SpawnSystem` cria um lobby seguro automaticamente e lê os pontos de
> spawn de `Workspace/PlayerTp`. Se essas pastas não existirem, ele avisa no
> Output do Studio.

---

## 🔐 Importante: troque os IDs de administrador

Os sistemas de admin têm **UserIds fixos no código**. Hoje estão configurados
para os IDs de teste: `1595442496`, `8833465560`, `1832521992`.

**Troque pelos seus** (seu UserId do Roblox) nestes 3 arquivos:
- `src/StarterPlayer/StarterPlayerScripts/AdminMenuClient.client.luau`
- `src/StarterPlayer/StarterPlayerScripts/UnifiedMenuClient.client.luau`
- `src/ServerScriptService/AdminSystemServer.server.luau`

Procure pela lista de IDs no topo de cada arquivo e substitua. (É só me pedir
que eu troco para você — me passe o seu UserId.)

---

## 🧩 Como os sistemas conversam (resumo)

- **`DataManager`** é o banco de dados central (`_G.PlayerDataManager`): moedas,
  bounty, personagens, stats. Quase todos os outros sistemas leem/escrevem nele.
- **`MainSystemInitializer`** cria as pastas e todos os `RemoteEvent`s/
  `RemoteFunction`s que ligam cliente e servidor.
- **`UnifiedMenuClient`** é o **hub** (botão ☰). Os menus (Loja, Times, Missões,
  Música, Tutorial, Admin) se registram nele automaticamente.
- **`GlobalSync` (servidor) + `ClientSync` (cliente)** mantêm os dados do
  jogador atualizados na tela (moedas, etc.).

Os scripts se auto-coordenam (esperam uns aos outros com `WaitForChild`/`_G`),
então **a ordem de carregamento não importa** — basta colocar todos no lugar.

---

## ⚠️ Pontos para verificar no teste

1. **Espectador**: o `SpectatorClient` (do projeto Explosive Battlegrounds) se
   conecta ao `SpawnSystem` pelo RemoteEvent `SpectatorMode`. Funciona, mas vale
   confirmar a câmera livre no lobby ao testar.
2. **Aba "Despertar" (Awakening)** no menu de personagens: depende de um
   `AwakeningSystem` que **não foi incluído** (você não pediu). O resto do menu
   funciona; só essa aba fica inativa até adicionar esse sistema.
3. **Missões**: as 3 missões diárias (matar 5, juntar 500 moedas, jogar 30 min)
   vêm no `DailyRewardsServer`. O progresso ainda é básico no código original —
   posso completá-lo se você quiser.

---

## ➕ Adicionar personagens

Para cada personagem novo, edite **3 arquivos** (o nome do personagem precisa
ser idêntico nos três):
1. `DataManager.server.luau` → tabela de preços/configuração
2. `GameManager.server.luau` → preço + vida (`characterHealth`)
3. `CharacterSystemClient.client.luau` → dados da loja (UI)

E crie a pasta `ReplicatedStorage/Characters/NomeDoPersonagem` com as Tools.
Guias detalhados (dos projetos originais) estão em `docs/referencia/`.
