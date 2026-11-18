# openslide-hub

Aggregate slide decks from multiple [open-slide](https://github.com/open-slide/open-slide) repositories into a single categorized hub workspace, while keeping each deck's source files inside its own project repository.

## Why

In AI-agent workflows, slide decks often live inside individual project repos (`project-a/slides/`, `project-b/slides/`) so coding agents can read project data and commit slides alongside code. That makes it hard to:

1. **Browse all decks in one place** on a single dev server grouped by project folder.
2. **Keep `@open-slide/core` and built-in agent skills in sync** across every repository.

`openslide-hub` solves both without patching `@open-slide/core`: it links each registered repository's `slides/`, `assets/`, and `themes/` into one hub workspace and maintains `slides/.folders.json` sidebar folders automatically.

## Install

Requirements: Node.js 20+.

```bash
git clone https://github.com/Chiuuu0209/openslide-hub.git
cd openslide-hub
./install.sh          # links CLI to ~/.local/bin/openslide-hub + installs OpenCode & Claude Code skill
```

Or install globally with npm:

```bash
npm install -g git+https://github.com/Chiuuu0209/openslide-hub.git
```

## Quick start

```bash
# 1. Create or pick an open-slide workspace to act as your central hub
npx @open-slide/cli init ~/slides-hub
openslide-hub init ~/slides-hub

# 2. Auto-discover and register all open-slide projects under a directory
openslide-hub scan ~/projects --add

# Or register individual projects with custom folder names and emoji/color icons:
openslide-hub add ~/projects/project-alpha/slides --name "Project Alpha" --icon "🤖"
openslide-hub add ~/projects/research-notes/slides --name "Research Notes" --icon "🧮"

# 3. Sync symlinks & .folders.json, or start the hub dev server
openslide-hub sync
openslide-hub dev
```

## Commands

| Command | Description |
|---|---|
| `openslide-hub init [hub-dir]` | Set the central hub workspace directory |
| `openslide-hub add <dir> [--name N] [--icon E]` | Register a source repo (or its `slides/` subdir) and sync |
| `openslide-hub rm <name-or-dir>` | Unregister a source and clean up its symlinks |
| `openslide-hub scan [root-dir] [--add]` | Discover all `@open-slide/core` workspaces under `root-dir` |
| `openslide-hub list [--json]` | Show registered sources, deck counts, and installed `@open-slide/core` versions |
| `openslide-hub sync` | Refresh deck/asset/theme symlinks and merge `slides/.folders.json` |
| `openslide-hub dev [args...]` | Run `sync` then launch `open-slide dev` inside the hub |
| `openslide-hub update-all` | Upgrade `@open-slide/core@latest` and run `open-slide sync:skills` across hub and all sources |
| `openslide-hub doctor` | Verify hub, sources, version consistency, and v1->v2 migration issues |

## Key behaviors

- **Zero-copy editing**: Because decks are symlinked, edits made through the hub's visual inspector or comments write directly back to the original project repository.
- **Deck ID collision handling**: If two sources both have a deck with the same directory name (e.g., `overview`), the colliding deck is linked as `<source-slug>--overview` and placed in its project folder.
- **Non-destructive `.folders.json` merge**: Any custom folders or local non-symlink decks created directly inside the hub are preserved across `openslide-hub sync`.
- **Automatic v1 -> v2 cleanups**: `openslide-hub update-all` automatically strips legacy `"vite"` dependencies left over from `open-slide` v1 that would otherwise conflict with v2's bundled Vite.

## Configuration

Per-machine configuration is stored outside the repository at `~/.config/openslide-hub/config.json` (override with `OPENSLIDE_HUB_CONFIG`).

## Tests

```bash
./tests/smoke.sh
```
