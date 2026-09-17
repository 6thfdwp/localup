# Zellij (optional)

An alternative multiplexer for the parallel-agent workflow. The tmux setup
(`make agentup`, `wt`, `wt-rm`, `wt-jump`) is separate and unaffected — use
either, or both.

```sh
make zellijup          # install zellij, link config + layouts
make zellijup-check    # report state, change nothing
```

## Files

| Repo | Linked to |
|---|---|
| `config.kdl` | `~/.config/zellij/config.kdl` |
| `layouts/agent.kdl` | `~/.config/zellij/layouts/agent.kdl` |

Symlinked, so edits here apply live and stay in git.

## Using it

From inside a worktree:

```sh
zellij --layout agent -s age-883-webform-email     # agent pane left, shell right
zellij attach age-883-webform-email                # come back later
```

Add another task as a tab in the session you're already in:

```sh
zellij action new-tab --layout agent --name <task> --cwd <worktree>
```

## Keys

Zellij starts **locked**: every key goes to the agent or shell, so nothing
collides with Claude Code. This is Zellij's own "Unlock First (non-colliding)"
preset. `Ctrl g` unlocks; any action drops you back to locked.

| Keys | Does |
|---|---|
| `Alt ←` / `Alt →` | move between panes, and across tabs at the edge |
| `Alt n` / `Alt f` | new pane / toggle floating panes |
| `Ctrl g` `t` `1..9` | jump to tab |
| `Ctrl g` `o` `w` | session manager — fuzzy-switch sessions |
| `Ctrl g` `o` `d` | detach; agents keep running |
| `Ctrl g` `p` `f` | fullscreen the focused pane |
| `Ctrl g` `s` | scroll mode (`Ctrl c` to exit) |

The status bar at the bottom shows the keys for whatever mode you're in.

`Alt` shortcuts need Option to send Meta. In Zed, set `terminal.option_as_meta`
to `true`; in Ghostty, `macos-option-as-alt = true`.
