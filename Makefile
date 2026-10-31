SHELL := /bin/bash

.PHONY: help

help:
	@echo 'core/Clash.Meta holds vendored core sources, not a git submodule;'
	@echo 'it is committed to this repository and needs no initialisation.'
	@echo ''
	@echo 'The Go core and Rust helper build automatically through the setup build'
	@echo 'hook during flutter build; see setup.dart and plugins/setup/.'
