# Makefile to manage the Mac setup script

.PHONY: localup

# Target to run the local Mac setup script
init:
	bash init.sh

devup:
	bash dev.sh

gitconfig:
	bash gitsetting.sh

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