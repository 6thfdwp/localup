# Parallel-agent workflow

One coding agent per git worktree, one tmux window per worktree. Lets several
agents work at once without fighting over files, branches, ports, or databases.

Install with `make agentup` from the repo root (`make agentup-check` to see
what would change first). Everything here is symlinked into place, so editing
these files updates your live setup and the change is tracked in git.

## What's here

| File | Installs to | Purpose |
|---|---|---|
| `bin/wt` | `~/.local/bin/wt` | Create/enter a worktree + its tmux window |
| `bin/wt-rm` | `~/.local/bin/wt-rm` | Tear one down, with safety guards |
| `tmux.conf` | `~/.tmux.conf` | Window-per-task tmux setup |
| `ghostty.conf` | Ghostty app support dir | Terminal config |
| `wt/example.conf` | `~/.config/wt/` | Template for onboarding a new repo |

## Daily use

```
wt fix-parser      # worktree + tmux window, deps installed, ready to go
wt                 # fzf-pick an existing worktree
wt-rm fix-parser   # tear down; refuses if uncommitted or unpushed
wt-rm --merged     # sweep everything already merged into main
```

In tmux: `Ctrl+b Space` fuzzy-jumps between tasks, `Alt+h`/`Alt+l` step between
them, `Ctrl+b d` detaches and leaves agents running, `Ctrl+b m` toggles mouse.

Worktrees live in `<repo>/.claude/worktrees/<slug>` on branch `wt/<slug>`.

## Adding a repo

Nothing is required. `wt <slug>` works in any git repo out of the box — it
detects the trunk branch (main, master, or whatever `origin/HEAD` says) and
adds `.claude/worktrees/` to that repo's `.git/info/exclude` on first use, so
worktrees never show up in `git status`.

Add a config only when a repo needs files copied in or dependencies installed:

```
cp ~/.config/wt/example.conf <repo>/.wt.conf
echo '.wt.conf' >> <repo>/.git/info/exclude
```

Set `WT_COPY` to the gitignored files a fresh checkout needs (`.env` and
friends) and `WT_SETUP` to the install command.

The config belongs next to the repo because that's what it describes — how
*that* codebase installs and what it collides on. `info/exclude` keeps it out
of `git status` without touching a shared `.gitignore`, so a personal setup
stays personal. `~/.config/wt/<repo-name>.conf` still works and is sourced
second, for anything genuinely specific to one machine.

The part worth thinking about is `wt_configure`. Parallel worktrees share
whatever your app talks to locally — the same Postgres, the same Redis, the
same port. Without isolation, two agents running tests corrupt each other's
data. If those are env-driven, rewriting them per worktree fixes it entirely;
see `wt/csp-arxiv-service.conf` for a working example.

## Notes

Per-repo configs deliberately live outside the repos they configure, so machine-
local setup never shows up in `git status` of a shared codebase.

`macos-option-as-alt = true` in `ghostty.conf` is load-bearing — without it
macOS eats Option and none of the `Alt`-based tmux bindings fire.
