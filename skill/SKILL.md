---
name: openslide-hub
description: Aggregate multiple open-slide repositories into a single categorized hub and upgrade @open-slide/core across workspaces. Use when managing multiple open-slide slide directories, adding a new repo's slides to the central hub, or updating open-slide versions and skills across repos.
---

# openslide-hub

`openslide-hub` aggregates slide decks from multiple repositories (`<repo>/slides`) into one central `open-slide` hub workspace using symlinks and `.folders.json` sidebar categories, while keeping the actual slide files inside each project's own repository.

## Commands

```bash
openslide-hub list                                      # show hub path, registered sources, deck counts, and versions
openslide-hub doctor                                    # check hub, sources, and @open-slide/core version consistency
openslide-hub scan <workspace-root> [--add]             # discover all open-slide workspaces under a directory
openslide-hub add <dir> [--name "Label"] [--icon "📊"]  # register a repo (or its slides/ subdir) and sync
openslide-hub rm <name-or-dir>                          # unregister a source and clean up its symlinks
openslide-hub sync                                      # refresh symlinks (slides, assets, themes) and .folders.json
openslide-hub dev [--port <port>]                       # sync and start open-slide dev in the hub
openslide-hub update-all                                # upgrade @open-slide/core@latest + sync:skills in hub and all sources
```

## Workflow notes

- **Authoring slides stays in the project repo**: create or edit slides in the project's own `slides/` directory so git history and project context stay together. Run `openslide-hub sync` afterwards so the new deck appears in the hub under that project's folder.
- **Deck ID collisions**: if two repositories contain a deck with the same folder name (e.g. `overview`), `openslide-hub sync` automatically prefixes the colliding symlink as `<source-slug>--overview` and assigns it to the source's folder.
- **Non-destructive folders**: folders created manually inside the hub UI (and non-symlink local decks in the hub) are preserved across `openslide-hub sync`.
