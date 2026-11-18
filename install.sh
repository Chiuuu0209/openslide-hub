#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MODE="link"
DRY_RUN=0
UNINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy) MODE="copy"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)
      echo "Usage: ./install.sh [--copy] [--dry-run] [--uninstall]"
      exit 0
      ;;
    *) echo "install.sh: unknown option $1" >&2; exit 2 ;;
  esac
done

install_item() {
  local src="$1" dst="$2"
  if ((UNINSTALL)); then
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      echo "  rm      $dst"
      ((DRY_RUN)) || rm -f "$dst"
    fi
    return
  fi

  ((DRY_RUN)) || mkdir -p "$(dirname "$dst")"
  if [[ "$MODE" == "link" ]]; then
    echo "  link    $dst -> $src"
    ((DRY_RUN)) || ln -sfn "$src" "$dst"
  else
    echo "  copy    $dst <- $src"
    if ((!DRY_RUN)); then
      rm -rf "$dst"
      cp -R "$src" "$dst"
    fi
  fi
}

echo "installing openslide-hub from $ROOT ($MODE)"
install_item "$ROOT/bin/openslide-hub" "$HOME/.local/bin/openslide-hub"

if [[ -d "$HOME/.config/opencode" ]]; then
  install_item "$ROOT/skill" "$HOME/.config/opencode/skills/openslide-hub"
fi
if [[ -d "$HOME/.claude" ]]; then
  install_item "$ROOT/skill" "$HOME/.claude/skills/openslide-hub"
fi
