# Makefile to manage the Mac setup script
#
# Preview any target without changing anything:
#   make init dryrun        (or: make init DRYRUN=1)

# `dryrun` is a pseudo-target: naming it anywhere on the command line sets DRYRUN=1.
ifneq ($(filter dryrun,$(MAKECMDGOALS)),)
export DRYRUN := 1
endif

.PHONY: init devup gitconfig warp-export rectangle-export agentup agentup-check dryrun
dryrun: ; @:

# Target to run the local Mac setup script
init:
	bash init.sh

devup:
	bash dev.sh

gitconfig:
	bash gitsetting.sh

# Save this machine's Warp settings into the repo
warp-export:
	cp ~/.warp/settings.toml warp-settings.toml

# Save this machine's Rectangle settings (customized shortcuts) into the repo
rectangle-export:
	defaults export com.knollsoft.Rectangle - | plutil -convert xml1 -o rectangle.plist -
	@for k in lastVersion SUHasLaunchedBefore SUEnableAutomaticChecks; do /usr/libexec/PlistBuddy -c "Delete :$$k" rectangle.plist 2>/dev/null || true; done

# Parallel-agent workflow: tmux + git worktree tooling (wt / wt-rm)
agentup:
	bash agentup.sh

agentup-check:
	bash agentup.sh --check

# Optional: Zellij as an alternative multiplexer (leaves the tmux setup alone)
zellijup:
	bash zellijup.sh

zellijup-check:
	bash zellijup.sh --check
# Add more targets as needed for additional setup tasks