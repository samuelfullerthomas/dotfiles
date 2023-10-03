.PHONY: machine bootstrap move tracking

move:
	./move-files.sh

bootstrap:
	./setup-machine-fundamentals.sh

tracking:
	./setup-git-tracking.sh

machine:
	./setup-machine.sh
	rm ~/.gitconfig
	cp ~/.gitconfig.personal ~/.gitconfig
