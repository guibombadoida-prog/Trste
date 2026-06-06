# GUIA — COMO ADICIONAR PERSONAGENS NO RETRO-VERSE
**Versão:** 1.0 · Março 2026
**Aplica-se a:** DataManager V4 + GameManager V6 + CharacterSystem Client V3

---

## REGRA DE OURO

Para adicionar **qualquer** personagem novo, você precisa editar **3 SCRIPTS** (e às vezes 4):

| # | Script | O que editar | Obrigatório? |
|---|--------|-------------|-------------|
| 1 | `DataManager_Server_V4` | Tabela `MIGRATION_CONFIG` | SIM |
| 2 | `GAME_MANAGER_V6` | Tabelas de preço + HP | SIM |
| 3 | `CHARACTER_SYSTEM_CLIENT_V3` | Tabela `characterData` (visual) | SIM |
| 4 | `CHARACTER_SYSTEM_CLIENT_V3` | Tabela `characterInfo` (habilidades/lore) | OPCIONAL |

Se faltar em QUALQUER um dos 3 obrigatórios, o personagem quebra.

---

## TIPOS DE PERSONAGEM

Existem 5 tipos. Cada tipo tem locais diferentes para editar:

| Tipo | Source | Exemplo | Vendável? | Trocável? |
|------|--------|---------|-----------|-----------|
| **Shop** | `"Shop"` | Guest, Danilo | SIM (25%) | SIM |
| **Mandatory** | `"Mandatory"` | Noob | NÃO | NÃO |
| **Bounty/Reward** | `"Reward"` | Maria | NÃO | SIM |
| **Gamepass** | `"Gamepass"` | Faker Gui | NÃO | NÃO |
| **Badge** | `"Badge"` | (futuro) | NÃO | NÃO |

---

## TIPO 1 — PERSONAGEM DE LOJA (Shop)

O jogador compra com moedas. É o mais simples.

### Passo 1: DataManager_Server_V4
Na tabela `MIGRATION_CONFIG.characterPrices`, adicione:

```lua
characterPrices = {
    Noob = 0,
    Guest = 50,
    Danilo = 200,
    ["Gui Bomba"] = 300,
    ["Dark Jc"] = 500,
    Shushuhus8 = 250,
    ["NOVO PERSONAGEM"] = 400,  -- ← ADICIONAR AQUI
},
```

### Passo 2: GAME_MANAGER_V6
Na tabela `characterPrices`, adicione o MESMO nome e preço:

```lua
local characterPrices = {
    Noob = 0,
    Guest = 50,
    Danilo = 200,
    ["Gui Bomba"] = 300,
    ["Dark Jc"] = 500,
    Shushuhus8 = 250,
    ["NOVO PERSONAGEM"] = 400,  -- ← ADICIONAR AQUI
}
```

Na tabela `characterHealth`, adicione o HP:

```lua
local characterHealth = {
    -- ... existentes ...
    ["NOVO PERSONAGEM"] = 230,  -- ← ADICIONAR AQUI
}
```

### Passo 3: CHARACTER_SYSTEM_CLIENT_V3
Na tabela `characterData.Loja`, adicione:

```lua
Loja = {
    -- ... existentes ...
    {name = "NOVO PERSONAGEM", price = 400, description = "Descrição curta", rarity = "HEROXIANOS"},
},
```

### Passo 4 (OPCIONAL): Habilidades e Lore
Na tabela `characterInfo`, adicione:

```lua
["NOVO PERSONAGEM"] = {
    abilities = {"🗡️ Habilidade 1", "🛡️ Habilidade 2", "💥 Habilidade 3"},
    stats     = "❤️ HP: 230 | ⚔️ Dano: Alto | 🛡️ Defesa: Média",
    lore      = "A história do personagem aqui."
},
```

### Passo 5: Criar pasta de Tools
No Roblox Studio, em `ReplicatedStorage > Characters`:
1. Criar uma **Folder** com o MESMO nome exato: `NOVO PERSONAGEM`
2. Dentro, colocar as **Tools** (armas/itens) do personagem
3. Cada Tool precisa de um **Handle** (Part ou MeshPart chamado "Handle")

### Passo 6: Imagem (OPCIONAL)
Em `ReplicatedStorage > CharacterImages`:
1. Criar um **ImageLabel** com o MESMO nome: `NOVO PERSONAGEM`
2. Definir a propriedade `Image` com o ID do asset (ex: `rbxassetid://123456`)

---

## TIPO 2 — PERSONAGEM DE BOUNTY (Reward)

O jogador desbloqueia ao atingir X bounty. NÃO custa moedas.

### Passo 1: DataManager_Server_V4
Na tabela `MIGRATION_CONFIG.bountyCharacters`:

```lua
bountyCharacters = {
    Maria = 2500,                    -- Nome = bounty necessário
    ["NOVO BOUNTY"] = 5000,          -- ← ADICIONAR AQUI
},
```

### Passo 2: GAME_MANAGER_V6
Na tabela `bountyCharacters` (MESMA):

```lua
local bountyCharacters = {
    Maria = 2500,
    ["NOVO BOUNTY"] = 5000,          -- ← ADICIONAR AQUI
}
```

Na tabela `characterHealth`:

```lua
["NOVO BOUNTY"] = 260,               -- ← ADICIONAR AQUI
```

**IMPORTANTE:** NÃO adicione na tabela `characterPrices`! Bounty characters não têm preço em moedas.

### Passo 3: CHARACTER_SYSTEM_CLIENT_V3
Na tabela `characterData.Recompensa`:

```lua
Recompensa = {
    {name = "Maria", bounty = 2500, price = 0, description = "Personagem de recompensa", rarity = "HEROXIANOS"},
    {name = "NOVO BOUNTY", bounty = 5000, price = 0, description = "Descrição", rarity = "BOSSXIANOS"},
},
```

**ATENÇÃO:** O campo `bounty = 5000` é usado pelo client para mostrar o custo. O campo `price = 0` DEVE ser 0.

### Passos 4-6: Mesmos do Shop
- characterInfo (opcional)
- Pasta de Tools em Characters
- Imagem em CharacterImages

---

## TIPO 3 — PERSONAGEM DE GAMEPASS

O jogador compra com Robux via Gamepass.

### Passo 1: DataManager_Server_V4
Na tabela `MIGRATION_CONFIG.gamepassCharacters`:

```lua
gamepassCharacters = {
    ["Faker Gui"] = 1247245466,
    ["Alma Perdida"] = 1161544217,
    ["NOVO GP"] = 9999999999,        -- ← ADICIONAR AQUI (ID do Gamepass)
},
```

### Passo 2: GAME_MANAGER_V6
Na tabela `gamepassCharacters`:

```lua
local gamepassCharacters = {
    ["Faker Gui"] = 1247245466,
    ["Alma Perdida"] = 1161544217,
    ["NOVO GP"] = 9999999999,        -- ← ADICIONAR AQUI
}
```

Na tabela `characterHealth`:

```lua
["NOVO GP"] = 300,                    -- ← ADICIONAR AQUI
```

**NÃO** adicione na `characterPrices`.

### Passo 3: CHARACTER_SYSTEM_CLIENT_V3
Na tabela `characterData.Gamepass`:

```lua
Gamepass = {
    {name = "Faker Gui", price = 0, description = "Solidão.....", rarity = "NULLXIANOS", gamepassId = 1247245466},
    {name = "Alma Perdida", price = 0, description = "Corrupção.....", rarity = "NULLXIANOS", gamepassId = 1161544217},
    {name = "NOVO GP", price = 0, description = "Descrição", rarity = "SUPREMO", gamepassId = 9999999999},
},
```

---

## TIPO 4 — PERSONAGEM DE BADGE

Igual ao Gamepass, mas usa BadgeService.

### Passo 1: DataManager_Server_V4
```lua
badgeCharacters = {
    ["NOVO BADGE"] = 123456789,      -- ID do Badge
},
```

### Passo 2: GAME_MANAGER_V6
```lua
local badgeIds = {
    ["NOVO BADGE"] = 123456789,
}
```
+ `characterHealth`

### Passo 3: CLIENT
Criar nova categoria `Badge` em `characterData` ou adicionar em `Recompensa`.

---

## CHECKLIST RÁPIDO

Antes de testar qualquer personagem novo:

- [ ] Nome EXATAMENTE igual em todos os 3 scripts (sem espaços extras!)
- [ ] `DataManager_Server_V4` → tabela correta em `MIGRATION_CONFIG`
- [ ] `GAME_MANAGER_V6` → tabela correta (prices/bounty/gamepass) + `characterHealth`
- [ ] `CHARACTER_SYSTEM_CLIENT_V3` → `characterData` na categoria certa
- [ ] Pasta de Tools criada em `ReplicatedStorage > Characters > [NomeExato]`
- [ ] (Opcional) Imagem em `CharacterImages`
- [ ] (Opcional) `characterInfo` com habilidades/lore

---

## RARIDADES DISPONÍVEIS

Use estas na tabela `characterData` do client:

| Raridade | Cor | Uso sugerido |
|----------|-----|-------------|
| `ROBLOXIANOS` | Cinza | Personagens básicos/iniciais |
| `HEROXIANOS` | Azul | Personagens intermediários |
| `NULLXIANOS` | Roxo | Gamepass / especiais |
| `BTUDIOS` | Laranja | Personagens raros |
| `BOSSXIANOS` | Vermelho | Bosses / bounty alto |
| `SUPREMO` | Dourado | Ultra raros |
| `AWAKENED` | Magenta | Formas despertadas (efeito especial) |

---

## ERROS COMUNS

### 1. "Personagem não aparece na loja"
**Causa:** Faltou adicionar em `characterData` no CLIENT.

### 2. "Comprei mas não equipa"
**Causa:** Nome diferente entre server e client. Verifique espaços extras!

### 3. "Bounty character não desbloqueia"
**Causa:** Faltou adicionar em `bountyCharacters` no GAME_MANAGER_V6 E no DataManager.

### 4. "Personagem não tem HP correto"
**Causa:** Faltou adicionar em `characterHealth` no GAME_MANAGER_V6. Sem entrada, o HP default é 100.

### 5. "Personagem aparece como '?' no inventário"
**Causa:** O personagem foi adquirido mas não existe em `characterData` do client. Adicione-o na categoria correta ou ele aparecerá como "Personagem especial" com raridade AWAKENED.

### 6. "Personagem de gamepass não auto-adiciona"
**Causa:** Faltou o ID correto em `gamepassCharacters` no GAME_MANAGER_V6. O sistema verifica gamepasses automaticamente ao entrar.

---

## EXEMPLO COMPLETO — Adicionando "Cyber Rex" (Bounty, 3000)

### DataManager_Server_V4:
```lua
bountyCharacters = {
    Maria = 2500,
    ["Cyber Rex"] = 3000,
},
```

### GAME_MANAGER_V6:
```lua
local bountyCharacters = {
    Maria = 2500,
    ["Cyber Rex"] = 3000,
}

local characterHealth = {
    -- ...
    ["Cyber Rex"] = 250,
}
```

### CHARACTER_SYSTEM_CLIENT_V3:
```lua
Recompensa = {
    {name = "Maria", bounty = 2500, price = 0, description = "Personagem de recompensa", rarity = "HEROXIANOS"},
    {name = "Cyber Rex", bounty = 3000, price = 0, description = "O caçador cibernético", rarity = "BOSSXIANOS"},
},
```

### characterInfo (opcional):
```lua
["Cyber Rex"] = {
    abilities = {"🔫 Laser Ocular", "🦾 Garra Metálica", "🛡️ Escudo Holográfico"},
    stats = "❤️ HP: 250 | ⚔️ Dano: Alto | 🛡️ Defesa: Média",
    lore = "Um dinossauro ressuscitado com tecnologia do futuro."
},
```

### Roblox Studio:
1. `ReplicatedStorage > Characters` → Nova Folder "Cyber Rex" com Tools dentro
2. `ReplicatedStorage > CharacterImages` → ImageLabel "Cyber Rex" com Image = rbxassetid://...

---

> **REGRA FINAL:** O nome do personagem é a chave de TUDO. Se você escrever `"Dark Jc "` (com espaço) em um lugar e `"Dark Jc"` (sem espaço) em outro, o sistema QUEBRA. Sempre copie e cole o nome entre os scripts!
