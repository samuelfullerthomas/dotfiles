# Day to day: edit files in this repo, then `make apply`. `make doctor` checks the
# machine, `make check` shows what `make apply` would change. New Mac: bootstrap.sh.
SHELL := /bin/bash
MACHINE ?= $(shell cat .machine 2>/dev/null)
export MACHINE
export HOMEBREW_MACHINE := $(MACHINE)

.PHONY: help apply apps link prefs check doctor machine require-machine

help:
	@echo "make apply    install apps, link dotfiles, set macOS prefs (MACHINE=$(or $(MACHINE),unset))"
	@echo "make apps | link | prefs    one step of apply"
	@echo "make check    lint the scripts and preview what apply would change"
	@echo "make doctor   read-only health check of this Mac"
	@echo "make machine MACHINE=work|personal    remember which machine this is"

require-machine:
	@case "$(MACHINE)" in work|personal) ;; *) echo "Set MACHINE=work|personal, e.g. make machine MACHINE=personal"; exit 1 ;; esac

machine: require-machine
	@echo "$(MACHINE)" > .machine && echo "This checkout is now the $(MACHINE) machine."

apply: apps link prefs

apps: require-machine
	brew bundle --file=Brewfile

link: require-machine
	./link.sh

prefs: require-machine
	./change-prefs.sh

check: require-machine
	shellcheck -x *.sh lib/*.sh
	@echo "--- Brewfile: missing"
	@brew bundle check --file=Brewfile --verbose --no-upgrade || true
	@echo "--- Brewfile: installed but not listed (report only)"
	@brew bundle cleanup --file=Brewfile || true
	@echo "--- Links"
	@./link.sh --dry-run

doctor:
	@./doctor.sh
