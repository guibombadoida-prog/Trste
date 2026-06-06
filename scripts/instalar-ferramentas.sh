#!/bin/bash
# ============================================================================
# instalar-ferramentas.sh - baixa as ferramentas Roblox usadas na validacao.
#
# Instala em ~/.local/bin:  selene, stylua, luau-lsp, rojo
# E baixa as definicoes de tipo do Roblox em  tools/globalTypes.d.luau
#
# Use quando quiser preparar o ambiente para rodar ./scripts/validar.sh.
# (Na sua maquina local, prefira o Rokit: `rokit install`.)
#
# Por que curl e nao Rokit aqui? No container do Claude Code na web ha um
# proxy TLS: o curl confia nele, mas o Rokit (que traz seus proprios
# certificados) falha. Por isso baixamos os binarios direto via curl.
# ============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# Versoes fixadas (espelham o rokit.toml). Assets para Linux x86_64.
SELENE_URL="https://github.com/Kampfkarren/selene/releases/download/0.31.0/selene-0.31.0-linux.zip"
STYLUA_URL="https://github.com/JohnnyMorganz/StyLua/releases/download/v2.5.2/stylua-linux-x86_64.zip"
LUAULSP_URL="https://github.com/JohnnyMorganz/luau-lsp/releases/download/1.68.0/luau-lsp-linux-x86_64.zip"
ROJO_URL="https://github.com/rojo-rbx/rojo/releases/download/v7.6.1/rojo-7.6.1-linux-x86_64.zip"

baixar_ferramenta() {
	local nome="$1" url="$2"
	if [ -x "$BIN_DIR/$nome" ]; then
		return 0 # ja instalado (idempotente)
	fi
	echo "  baixando $nome..."
	local tmp
	tmp="$(mktemp -d)"
	curl -sSL --retry 3 --max-time 180 -o "$tmp/pacote.zip" "$url"
	unzip -oq "$tmp/pacote.zip" -d "$tmp/extraido"
	local bin
	bin="$(find "$tmp/extraido" -type f -name "$nome" -print -quit)"
	install -m 0755 "$bin" "$BIN_DIR/$nome"
	rm -rf "$tmp"
}

echo "Preparando ferramentas Roblox (selene, StyLua, luau-lsp, rojo)..."
baixar_ferramenta selene "$SELENE_URL"
baixar_ferramenta stylua "$STYLUA_URL"
baixar_ferramenta luau-lsp "$LUAULSP_URL"
baixar_ferramenta rojo "$ROJO_URL"

# Definicoes de tipo do Roblox para o luau-lsp (game, Instance, Player...).
GT_FILE="$REPO_DIR/tools/globalTypes.d.luau"
mkdir -p "$REPO_DIR/tools"
if [ ! -s "$GT_FILE" ]; then
	echo "  baixando definicoes de tipo do Roblox..."
	curl -sSL --retry 3 --max-time 180 \
		-o "$GT_FILE" \
		"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau" || true
fi

echo "Pronto! Ferramentas em $BIN_DIR (adicione ao PATH se necessario)."
