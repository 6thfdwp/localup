# Makefile to manage the Mac setup script

.PHONY: localup

# Target to run the local Mac setup script
init:
	bash init.sh

ideup:
	bash vscode.sh
# Add more targets as needed for additional setup tasks