#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/bin/openslide-hub"
chmod +x "$BIN" "$ROOT/install.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/openslide-hub-smoke.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

export OPENSLIDE_HUB_CONFIG="$TMP/config.json"

pass=0
ok() { pass=$((pass + 1)); printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

make_workspace() {
  local dir="$1" ver="${2:-2.3.2}"
  mkdir -p "$dir/slides/getting-started" "$dir/assets" "$dir/themes" "$dir/node_modules/@open-slide/core"
  cat > "$dir/package.json" <<EOF
{
  "name": "$(basename "$dir")",
  "private": true,
  "dependencies": { "@open-slide/core": "^$ver", "react": "^19.3.1", "react-dom": "^19.3.1" }
}
EOF
  cat > "$dir/node_modules/@open-slide/core/package.json" <<EOF
{ "name": "@open-slide/core", "version": "$ver" }
EOF
}

# 1. version & help
"$BIN" --version | grep -q "openslide-hub 0.1.0" && ok "version" || fail "version"
"$BIN" --help | grep -q "aggregate multiple open-slide repos" && ok "help" || fail "help"

# 2. setup fixture hub and 2 source workspaces
HUB="$TMP/hub"
SRC_A="$TMP/proj-alpha/slides"
SRC_B="$TMP/proj-beta/slides"
make_workspace "$HUB" "2.3.2"
make_workspace "$SRC_A" "2.3.2"
make_workspace "$SRC_B" "2.3.2"

mkdir -p "$SRC_A/slides/deck-one" "$SRC_A/slides/shared-name" "$SRC_A/assets/logo-a"
echo "export default [];" > "$SRC_A/slides/deck-one/index.tsx"
echo "export default [];" > "$SRC_A/slides/shared-name/index.tsx"

mkdir -p "$SRC_B/slides/deck-two" "$SRC_B/slides/shared-name"
echo "export default [];" > "$SRC_B/slides/deck-two/index.tsx"
echo "export default [];" > "$SRC_B/slides/shared-name/index.tsx"
echo "# Theme B" > "$SRC_B/themes/brand-b.md"

# 3. init hub
"$BIN" init "$HUB" | grep -q "Initialized hub" && ok "init" || fail "init"

# 4. scan discovers SRC_A and SRC_B (and skips HUB)
scan_out="$("$BIN" scan "$TMP")"
echo "$scan_out" | grep -q "proj-alpha" && echo "$scan_out" | grep -q "proj-beta" && ok "scan discovers sources" || fail "scan"
! echo "$scan_out" | grep -q "$HUB" && ok "scan skips hub itself" || fail "scan skipped hub"

# 5. add sources (including passing parent repo path for SRC_A)
"$BIN" add "$TMP/proj-alpha" --name "Alpha" --icon "🤖" >/dev/null
"$BIN" add "$SRC_B" --name "Beta" --icon "#3b82f6" >/dev/null
[[ -L "$HUB/slides/deck-one" && -L "$HUB/slides/deck-two" ]] && ok "add + symlink decks" || fail "symlink decks"

# 6. collision handling: second `shared-name` becomes `beta--shared-name`
[[ -L "$HUB/slides/shared-name" && -L "$HUB/slides/beta--shared-name" ]] && ok "collision prefixing" || fail "collision prefixing"

# 7. assets & themes symlinked
[[ -L "$HUB/assets/logo-a" && -L "$HUB/themes/brand-b.md" ]] && ok "assets and themes symlinked" || fail "assets/themes"

# 8. preserve user-created folder & local deck in .folders.json
mkdir -p "$HUB/slides/local-custom-deck"
node -e '
const fs = require("fs");
const p = process.argv[1];
const m = JSON.parse(fs.readFileSync(p, "utf8"));
m.folders.push({ id: "f-deadbeef", name: "My Custom Folder", icon: { type: "emoji", value: "⭐" } });
m.assignments["local-custom-deck"] = "f-deadbeef";
fs.writeFileSync(p, JSON.stringify(m, null, 2));
' "$HUB/slides/.folders.json"

"$BIN" sync >/dev/null
grep -q "f-deadbeef" "$HUB/slides/.folders.json" && grep -q "local-custom-deck" "$HUB/slides/.folders.json" \
  && ok "preserves user folders and local decks" || fail "preserve user folders"

# 9. doctor passes when healthy
"$BIN" doctor | grep -q "doctor: ok" && ok "doctor healthy" || fail "doctor healthy"

# 10. list --json
"$BIN" list --json | grep -q '"name": "Alpha"' && ok "list --json" || fail "list --json"

# 11. rm removes source and cleans its symlinks while keeping local-custom-deck
"$BIN" rm "Beta" >/dev/null
[[ ! -L "$HUB/slides/deck-two" && ! -L "$HUB/slides/beta--shared-name" && -d "$HUB/slides/local-custom-deck" ]] \
  && ok "rm cleans source symlinks safely" || fail "rm cleanup"

printf 'all %d checks passed\n' "$pass"
