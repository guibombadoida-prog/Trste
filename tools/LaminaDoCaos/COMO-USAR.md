# 🗡️ Lâmina do Caos — como usar

Tool pronta. **Você só troca o mesh do Handle.** Tudo o mais já está montado.

## Importar no Studio
1. No Roblox Studio: clique direito em `Workspace` (ou `StarterPack`) →
   **Insert from File…** → escolha `LaminaDoCaos.rbxmx`.
2. A Tool **LaminaDoCaos** aparece já com tudo dentro:
   `Handle`, `Remote`, `CameraShake`, `LaminaDoCaos_Server_V1`,
   `LaminaDoCaos_Client_V1`.

## A única coisa que você mexe: o mesh
- Substitua a `Part` **Handle** pelo seu **MeshPart/Mesh** da espada.
- ⚠️ Mantenha o nome **exatamente** `Handle` (a Tool não funciona sem isso).
- Ajuste o **Grip** da Tool se a espada ficar torta na mão.

## Onde colocar a Tool
- `StarterPack` (todo jogador recebe), ou
- `ReplicatedStorage/Characters/<Personagem>` (sistema de personagens do jogo), ou
- na mochila de um NPC (ele usa a **Onda de Caos** sozinho).

## Habilidades
| Entrada | Habilidade |
|---|---|
| 🖱️ Clique (M1) | Combo de Lâmina |
| **Q** / botão | Onda de Caos (explosão em área) |
| **E** / botão | Projétil do Caos (mira no mouse) |
| **R** / botão | Salto Dimensional (teleporte + explosão) |

## Ajustes opcionais (no `LaminaDoCaos_Server_V1`, tabela `CONFIG`)
- Dano, alcance e cooldown de cada habilidade.
- `EXPLOSION_SOUND_ID` — troque pelo seu som de explosão.

> Já respeita: sem dano em aliados/time, sem dano em si mesmo, dá dano em NPCs,
> efeitos somem ao morrer, sem deletar partes, sem `math.random`, sem GUI.
