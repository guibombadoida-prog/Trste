# Campo de Batalha / Do Chaos 🎮💥

Repositório do jogo de Roblox **Campo de Batalha / Do Chaos**, feito para ser
desenvolvido com a ajuda do **Claude Code**.

Este README explica **como o repositório funciona** e **como levar os scripts
daqui para o Roblox Studio** do jeito certo. Foi escrito para iniciantes — leia
com calma. 🙂

---

## 🧠 A ideia principal (leia isto primeiro)

O Roblox Studio salva o jogo em um arquivo `.rbxl` (binário), que **não combina**
com Git nem com edição de texto. A solução é simples:

> **Este repositório guarda só os _scripts_ (texto), organizados igual à árvore
> do Roblox Studio.** Você copia cada script para o lugar certo no Studio.

Por isso, **cada pasta aqui corresponde a um serviço do Studio** e **o final do
nome de cada arquivo diz qual tipo de script criar**. Assim você nunca fica em
dúvida sobre onde colar cada coisa.

---

## 📛 Convenção dos nomes (a regra de ouro)

| Final do nome do arquivo | Vira no Studio  | Onde roda                                   |
| ------------------------ | --------------- | ------------------------------------------- |
| `Algo.server.luau`       | **Script**      | no **Servidor**                             |
| `Algo.client.luau`       | **LocalScript** | no **Cliente** (na máquina de cada jogador) |
| `Algo.luau` (sem sufixo) | **ModuleScript**| onde for `require()`-ado (código **compartilhado**) |

> 💡 Regra fácil: se o nome tem `.server` ou `.client`, é um script que **roda
> sozinho**. Se é só `.luau`, é uma **biblioteca** (ModuleScript) que outros
> scripts chamam com `require()`.

O **nome que você dá ao objeto no Studio** é o nome do arquivo **sem o sufixo**:

- `Main.server.luau` → um **Script** chamado **`Main`**
- `Main.client.luau` → um **LocalScript** chamado **`Main`**
- `Config.luau` → um **ModuleScript** chamado **`Config`**

---

## 🗂️ Onde cada pasta vai parar no Studio

| Pasta no repositório                      | Serviço no Studio                      | Para quê serve                                     |
| ----------------------------------------- | -------------------------------------- | -------------------------------------------------- |
| `src/ServerScriptService/`                | **ServerScriptService**                | Lógica do servidor (regras do jogo, dano, pontos)  |
| `src/ServerStorage/`                      | **ServerStorage**                      | Módulos e itens que **só o servidor** pode ver     |
| `src/ReplicatedStorage/`                  | **ReplicatedStorage**                  | Código/dados **compartilhados**, `RemoteEvent`s    |
| `src/StarterPlayer/StarterPlayerScripts/` | **StarterPlayer → StarterPlayerScripts** | Lógica do cliente (controles, câmera, interface) |
| `src/StarterGui/`                         | **StarterGui**                         | Telas e botões (interface do jogador)              |

> Quando seus arquivos grandes chegarem, é só ir colocando cada script na pasta
> que corresponde ao lugar dele no Studio.

---

## 📋 Passo a passo: copiar um script para o Studio

1. **Abra** o Roblox Studio e o seu jogo.
2. No painel **Explorer**, ache o **serviço** igual ao nome da pasta
   (ex.: a pasta `src/ServerScriptService/` → serviço `ServerScriptService`).
3. **Botão direito** no serviço → **Insert Object** → escolha o tipo certo
   conforme o sufixo do arquivo (**Script**, **LocalScript** ou **ModuleScript**).
4. **Renomeie** o objeto para o nome do arquivo **sem o sufixo**
   (ex.: `Main.server.luau` → renomeie para `Main`).
5. **Abra o arquivo aqui**, selecione **todo** o conteúdo (Ctrl+A), copie
   (Ctrl+C) e **cole** dentro do script no Studio (apague antes o texto que vem
   por padrão).
6. **Salve** (Ctrl+S) e clique em **Play** (▶️) para testar.

Repita para cada arquivo. Mantenha os nomes iguais aos do repositório para que
os `require()` entre scripts funcionem de primeira.

---

## 🔁 Como vamos trabalhar juntos

```
  Claude escreve/edita os scripts aqui  ──►  você copia para o Studio
                  ▲                                      │
                  │                                      ▼
        você me manda o feedback  ◄──────────  você TESTA no Studio (Play)
```

1. Eu crio ou ajusto os scripts neste repositório.
2. Você copia para o Studio (passo a passo acima) e **testa**.
3. Você me conta o que aconteceu (deu erro? ficou estranho? funcionou?).
4. Eu corrijo/melhoro e o ciclo recomeça.

---

## ✅ Validação automática (antes de chegar até você)

Para reduzir erros quando você for testar no Studio, **antes de te entregar um
script eu rodo três verificações** aqui no repositório:

| Ferramenta   | O que checa                                                        |
| ------------ | ------------------------------------------------------------------ |
| **StyLua**   | Formatação (deixa o código arrumado e padronizado)                 |
| **selene**   | Qualidade do código (variáveis não usadas, descuidos comuns)       |
| **luau-lsp** | **Tipos** e globais do Roblox (`game`, `Instance`, `Player`, etc.) |

Para rodar você mesmo (opcional):

```bash
./scripts/validar.sh          # valida a pasta src/ inteira
./scripts/validar.sh arquivo  # valida só um arquivo ou pasta
```

Na primeira vez, o script baixa as ferramentas sozinho. Se quiser só baixá-las:

```bash
./scripts/instalar-ferramentas.sh
```

---

## 🧰 (Opcional) Configurar na sua própria máquina

Se um dia quiser editar/validar localmente, o jeito recomendado no mundo Roblox é:

1. Instale o **[Rokit](https://github.com/rojo-rbx/rokit)** (gerenciador de
   ferramentas) e, na pasta do projeto, rode:
   ```bash
   rokit install
   ```
   Isso baixa exatamente as versões do `rokit.toml` (Rojo, selene, StyLua, luau-lsp).
2. No **VS Code**, instale as extensões **luau-lsp**, **selene** e **StyLua**.
3. (Avançado) Use o **Rojo** para sincronizar tudo de uma vez com o Studio, em
   vez de copiar arquivo por arquivo — veja a seção abaixo.

---

## 🚀 (Opcional, avançado) Importar tudo de uma vez

Em vez de copiar script por script, dá para trazer o projeto inteiro com o **Rojo**:

- **Gerar um arquivo de lugar** para abrir no Studio:
  ```bash
  rojo build default.project.json --output CampoDeBatalha.rbxlx
  ```
  Depois, no Studio: **File → Open from File…** e escolha o `.rbxlx`.

- **Sincronização ao vivo** (o código atualiza no Studio enquanto você edita):
  rode `rojo serve` e, no Studio, use o plugin do Rojo para **Connect**.

> Para o nosso fluxo do dia a dia, copiar e colar já basta. Deixe isto para
> quando você estiver mais confortável.

---

## 📁 Estrutura atual do repositório

```
.
├── README.md                  ← este guia
├── default.project.json       ← mapa: pastas src/ ↔ serviços do Studio (Rojo)
├── rokit.toml                 ← versões das ferramentas (uso local)
├── selene.toml                ← config do linter
├── stylua.toml                ← config do formatador
├── .luaurc                    ← config da checagem de tipos Luau
├── scripts/
│   ├── validar.sh             ← valida formatação + lint + tipos
│   └── instalar-ferramentas.sh← baixa as ferramentas
└── src/                       ← TODOS os scripts do jogo ficam aqui
    ├── ServerScriptService/
    │   └── Main.server.luau   ← exemplo: Script do servidor
    ├── ServerStorage/
    ├── ReplicatedStorage/
    │   └── Config.luau        ← exemplo: ModuleScript compartilhado
    ├── StarterGui/
    └── StarterPlayer/
        └── StarterPlayerScripts/
            └── Main.client.luau ← exemplo: LocalScript do cliente
```

> Os arquivos em `src/` hoje são só **exemplos** que mostram a convenção. Pode
> apagá-los quando seus scripts de verdade chegarem.

---

## 📖 Glossário rápido

- **Servidor x Cliente**: o **servidor** é o "juiz" do jogo (vale para todos);
  o **cliente** é o que roda na máquina de cada jogador (controles, tela).
- **Script**: roda no servidor.
- **LocalScript**: roda no cliente.
- **ModuleScript**: uma "biblioteca" de código que outros scripts usam com
  `require()`. Não roda sozinho.
- **RemoteEvent**: a "ponte" para o cliente e o servidor conversarem.
- **Explorer**: o painel do Studio que mostra a árvore de objetos do jogo.

---

Qualquer dúvida, é só me chamar aqui no Claude Code. Bom desenvolvimento! 🚀
