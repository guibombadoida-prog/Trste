# 📖 GUIA — ADICIONAR NOVO PERSONAGEM
## Explosive Battlegrounds — Retro-Verse / Studios
**Versão:** 1.0 | Para usar com o sistema atual (DataManager V1 + GameManager V2)

---

## 🗂️ CHECKLIST RÁPIDO

Antes de começar, responda SIM para todos os itens:

- [ ] Tenho o modelo do personagem (R6 rigged)?
- [ ] Defini nome, preço e raridade?
- [ ] Vou adicionar tools exclusivas ou usar o Fists padrão?
- [ ] Tenho permissão para usar o modelo?

---

## 📋 PASSO A PASSO COMPLETO

---

### PASSO 1 — Preparar o modelo do personagem

1. Abra o Roblox Studio com o projeto **Explosive Battlegrounds**
2. Importe ou crie o modelo do personagem (deve ser **R6**)
3. Certifique que o modelo tem todas as partes obrigatórias:
   ```
   [Model]
   ├── HumanoidRootPart  ← obrigatório
   ├── Torso
   ├── Head
   ├── Left Arm
   ├── Right Arm
   ├── Left Leg
   ├── Right Leg
   ├── Humanoid
   └── Animate (opcional — copia do personagem padrão)
   ```
4. Nomeie o modelo exatamente como você quer que apareça no jogo
   - ✅ `Calebe`
   - ✅ `Gui a Bomba`
   - ❌ `calebe` (letras minúsculas quebram o sistema)

---

### PASSO 2 — Colocar o modelo na pasta correta

No **ReplicatedStorage**, abra a pasta `Characters` e cole o modelo lá dentro:

```
ReplicatedStorage/
└── Characters/
    ├── Block        ← já existe
    ├── Noob         ← já existe
    ├── Rthro        ← já existe
    ├── Skinned      ← já existe
    └── SeuPersonagem  ← ADICIONAR AQUI
```

---

### PASSO 3 — Registrar no DataManager

Abra o script `DataManager` em **ServerScriptService**.

Localize a tabela `MIGRATION_CONFIG` e adicione o personagem:

```lua
local MIGRATION_CONFIG = {
    mandatoryCharacters = {"Block"},  -- personagens sempre disponíveis (grátis)
    characterPrices = {
        Block   = 0,
        Noob    = 50,
        Rthro   = 100,
        Skinned = 150,
        -- ▼ ADICIONAR AQUI ▼
        SeuPersonagem = 200,  -- defina o preço em moedas
    },
    bountyCharacters   = {},
    gamepassCharacters = {},
    badgeCharacters    = {},
}
```

**Tipos de personagem disponíveis:**

| Tipo | Como adicionar | Vendável? |
|---|---|---|
| `Shop` (padrão) | Coloca em `characterPrices` | ✅ Sim (25%) |
| `Mandatory` | Coloca em `mandatoryCharacters` | ❌ Não |
| `Reward` | Coloca em `bountyCharacters` | ✅ Sim |
| `Gamepass` | Coloca em `gamepassCharacters` | ❌ Não |

**Exemplo — personagem de recompensa (bounty):**
```lua
bountyCharacters = {
    SeuPersonagem = true,  -- ganho por bounty/missão
},
```

---

### PASSO 4 — Registrar no GameManager

Abra o script `GameManager` em **ServerScriptService**.

Localize as duas tabelas e adicione:

```lua
-- ► Tabela de preços (DEVE ser igual ao DataManager)
local characterPrices = {
    Block   = 0,
    Noob    = 50,
    Rthro   = 100,
    Skinned = 150,
    SeuPersonagem = 200,  -- ← ADICIONAR
}

-- ► HP do personagem na batalha
local characterHealth = {
    Block   = 100,
    Noob    = 100,
    Rthro   = 120,
    Skinned = 150,
    SeuPersonagem = 130,  -- ← ADICIONAR (sugestão: 80-200)
}
```

---

### PASSO 5 — Registrar no CharacterSystemClient (loja visual)

Abra o script `CharacterSystemClient` em **StarterPlayer > StarterPlayerScripts**.

Localize a tabela `CHARACTERS` e adicione uma linha:

```lua
local CHARACTERS = {
    {name="Block",   price=0,   rarity="BASICO",   lore="O clássico Robloxian"},
    {name="Noob",    price=50,  rarity="BASICO",   lore="O lendário Noob"},
    {name="Rthro",   price=100, rarity="RARO",     lore="Estilo moderno R15"},
    {name="Skinned", price=150, rarity="ESPECIAL", lore="Visual Skinned exclusivo"},
    -- ▼ ADICIONAR AQUI ▼
    {name="SeuPersonagem", price=200, rarity="RARO", lore="Descrição do personagem"},
}
```

**Raridades disponíveis:**

| Raridade | Cor | Uso sugerido |
|---|---|---|
| `"BASICO"` | Cinza | Personagens iniciais, comuns |
| `"RARO"` | Azul | Personagens intermediários |
| `"ESPECIAL"` | Roxo | Personagens difíceis de obter |
| `"EPICO"` | Dourado | Lendários, eventos, exclusivos |

---

### PASSO 6 — Habilidades passivas (opcional)

Se o personagem tiver info de habilidades no popup, adicione no `CharacterSystemClient`:

```lua
-- Localize a tabela charInfo e adicione:
local charInfo = {
    -- ... personagens existentes ...
    SeuPersonagem = {
        stats     = "❤️ HP:130 | ⚔️ Dano:Médio",
        abilities = {
            "👊 Soco Especial",
            "🛡️ Defesa Avançada",
            "💨 Dash Duplo"
        }
    },
}
```

---

### PASSO 7 — Tools exclusivas (opcional)

Se o personagem tiver tools próprias além do Fists padrão:

1. Crie uma pasta com o **nome exato** do personagem dentro de:
   ```
   ReplicatedStorage/
   └── CharacterTools/
       └── SeuPersonagem/   ← criar esta pasta
           ├── [Tool]        ← opção A: tool direta
           └── [StringValue] ← opção B: nome de tool do ServerStorage
   ```

2. **Opção A — Tool direta:** coloque a tool dentro da pasta
3. **Opção B — StringValue:** crie um `StringValue` cujo **Value** é o nome da tool em `ServerStorage/Tools`

   ```
   StringValue
   Name:  "MinhaArma"
   Value: "Lightning Cannon (vfx tiro.)"  ← nome exato da tool no ServerStorage
   ```

Se a pasta `CharacterTools/SeuPersonagem/` estiver **vazia**, o jogador receberá `Fists (Soco)` por padrão.

---

### PASSO 8 — Verificação final

Teste rodando o jogo (via MCP execute_luau ou Test > Play):

```
✅ Personagem aparece na loja com o card correto?
✅ ViewportFrame mostra o modelo do personagem?
✅ Preço está correto?
✅ Ao comprar, aparece no inventário?
✅ Ao equipar, o morph funciona?
✅ Tools são entregues corretamente?
✅ HP no batalha está correto?
✅ Dados são salvos no DataStore após 60s?
```

---

## 🚫 ERROS COMUNS

| Erro | Causa | Solução |
|---|---|---|
| Card não aparece | Nome errado em CHARACTERS | Verificar ortografia exata |
| "Personagem não encontrado" | Não está em characterPrices | Adicionar no DataManager e GameManager |
| ViewportFrame vazio | Modelo não está em RS/Characters | Mover modelo para a pasta correta |
| Morph não funciona | Falta HumanoidRootPart | Verificar estrutura R6 do modelo |
| Tools não aparecem | Pasta CharacterTools errada | Verificar nome exato da pasta |
| DataStore não salva | Nome diferente nos 3 scripts | Usar nome **idêntico** nos 3 lugares |
| Preço 0 mas pede coins | characterPrices incorreto | Verificar se é 0 (zero) e não "0" |

---

## 📐 TEMPLATE COMPLETO

Copie este template e preencha para cada personagem novo:

```
Nome do personagem : _______________
Preço (moedas)     : _______________
Raridade           : BASICO / RARO / ESPECIAL / EPICO
HP na batalha      : _______________
Tipo               : Shop / Mandatory / Reward / Gamepass
Lore (1 linha)     : _______________
Abilities (3 itens): 1. _____________
                     2. _____________
                     3. _____________
Tools exclusivas   : Sim / Não
  Se sim, quais    : _______________
```

---

## 🔄 ORDEM DE EDIÇÃO DOS SCRIPTS

Sempre edite nesta ordem para evitar desincronização:

```
1. DataManager      → MIGRATION_CONFIG.characterPrices
2. GameManager      → characterPrices + characterHealth
3. CharacterSystem  → CHARACTERS + charInfo (opcional)
4. CharacterTools/  → pasta de tools (opcional)
5. RS/Characters/   → modelo do personagem
```

---

## 📦 EXEMPLO COMPLETO — Personagem "Danilo"

**Especificações:**
- Preço: 0 (grátis)
- Raridade: BASICO
- HP: 100
- Tool: `fish` (já existe no ServerStorage/Tools)

**DataManager:**
```lua
characterPrices = {
    ...,
    Danilo = 0,
},
```

**GameManager:**
```lua
characterPrices = { ..., Danilo = 0 }
characterHealth = { ..., Danilo = 100 }
```

**CharacterSystemClient:**
```lua
{name="Danilo", price=0, rarity="BASICO", lore="O pescador lendário"},
```

**CharacterTools/Danilo/:**
```
StringValue
  Name:  "FishTool"
  Value: "fish"
```

**ReplicatedStorage/Characters/Danilo** — modelo R6 do Danilo colocado aqui.

---

*Explosive Battlegrounds — Retro-Verse / Studios | Guia v1.0*
