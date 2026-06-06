#!/bin/bash
# ============================================================================
# validar.sh - checa TODOS os scripts em src/ antes de leva-los ao Studio.
#
#   ./scripts/validar.sh            valida a pasta src/ inteira
#   ./scripts/validar.sh arquivo    valida so um arquivo/pasta
#
# Roda tres ferramentas:
#   1. StyLua   -> formatacao consistente
#   2. selene   -> qualidade de codigo (variaveis nao usadas, shadowing...)
#   3. luau-lsp -> checagem de TIPOS e globais do Roblox
# ============================================================================
set -uo pipefail

cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"

# Garante as ferramentas (instala se faltar alguma).
if ! command -v selene >/dev/null 2>&1 ||
	! command -v stylua >/dev/null 2>&1 ||
	! command -v luau-lsp >/dev/null 2>&1; then
	echo "Ferramentas ausentes; instalando..."
	bash "$(dirname "$0")/instalar-ferramentas.sh"
fi

ALVO="${1:-src}"
GT="tools/globalTypes.d.luau"
status=0

echo "==> StyLua (formatacao)"
if stylua --check "$ALVO"; then
	echo "    ok"
else
	echo "    >> rode 'stylua $ALVO' para corrigir a formatacao automaticamente."
	status=1
fi

echo "==> selene (qualidade de codigo)"
if selene "$ALVO"; then
	echo "    ok"
else
	status=1
fi

echo "==> luau-lsp (tipos)"
# Sourcemap ajuda o luau-lsp a resolver require() entre scripts.
if command -v rojo >/dev/null 2>&1; then
	rojo sourcemap default.project.json --output sourcemap.json >/dev/null 2>&1 || true
fi
defs_arg=()
[ -s "$GT" ] && defs_arg=(--defs="$GT")
sm_arg=()
[ -s sourcemap.json ] && sm_arg=(--sourcemap=sourcemap.json)
if luau-lsp analyze --platform=roblox "${defs_arg[@]}" "${sm_arg[@]}" "$ALVO"; then
	echo "    ok"
else
	status=1
fi

echo
if [ "$status" -eq 0 ]; then
	echo "OK - tudo certo, pode levar pro Studio."
else
	echo "ATENCAO - ha avisos/erros acima para revisar."
fi
exit $status
