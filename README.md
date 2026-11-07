# localup

Scripts to set up the same working environment on a new Mac.

## New machine

```bash
# 1. Clone over HTTPS (no SSH key yet). The first git/make call on a clean Mac
#    pops up the Command Line Tools installer: accept it and wait.
git clone https://github.com/6thfdwp/localup.git ~/localup
cd ~/localup

# 2. Optional preview of step 3, no Command Line Tools needed.
DRYRUN=1 bash init.sh

# 3. Run the steps in order.
bash init.sh      # first run: `make` itself needs the Command Line Tools
make gitconfig    # git identity + SSH key (copied to clipboard; add it on GitHub)
make devup        # languages, fonts, editors, terminal
make agentup      # tmux, worktree tools, Claude Code skills/plugins/MCP
```

Clone somewhere stable. Config files are symlinked back into this repo, so
moving the folder later breaks them; re-running `make devup` / `make agentup`
from the new location relinks them.

## What each step does

| Target | Does |
|---|---|
| `make init` | Xcode Command Line Tools, Homebrew, git, zsh, Oh My Zsh, Chrome, Rectangle |
| `make gitconfig` | Prompts for git name/email, sets defaults, generates an SSH key (interactive) |
| `make devup` | nvm + Node LTS, `g` + Go 1.27.3, `uv`, JetBrains Mono, Warp + settings, Zed + keymap, zsh config |
| `make agentup` | tmux, fzf, `wt` / `wt-rm` / `wt-jump`, Claude Code skills, plugins and Linear MCP (details in `agent/README.md`) |
| `bash zellijup.sh` | Optional Zellij alternative to tmux |

## Dry run

Add `dryrun` to any target to see what would change without changing anything:

```bash
make devup dryrun      # same as: make devup DRYRUN=1
```

Installed items show `✓`; everything else is printed as `[dry-run] <command>`.
`make agentup-check` is the older spelling for agentup.

## Options

- `GO_VERSION=1.26.10 make devup` installs a different Go (default 1.27.3).
- `SETUP_VSCODE=1 make devup` also installs VSCode extensions and settings
  (off by default).

## Keeping the repo in sync

- **zsh:** `~/.zshrc` sources `zshrc.shared`, so edit that file in the repo. The
  old `~/.zshrc` is backed up once as `~/.zshrc.bak.<time>`; machine-specific
  lines go in `~/.zshrc` below the source line.
- **Zed keymap, tmux config, worktree tools:** symlinked, so editing the live
  file edits the repo. Just commit.
- **Warp settings:** copied, because Warp rewrites its own file. After changing
  settings, run `make warp-export` and commit `warp-settings.toml`.
- **VSCode settings:** copied; re-export by hand into `vs-settings.json`.
- Existing files are never overwritten silently: they are backed up or left alone.

## Not covered yet

- `gitalias` is not applied (`gitsetting.sh` sets the same alias itself).

This repo is public: keep tokens, keys and work details out of it.
