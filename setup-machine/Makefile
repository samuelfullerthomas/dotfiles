.PHONY: machine bootstrap move

move:
	./move-files.sh

bootstrap:
	./setup-machine-fundamentals.sh
	./setup-ssh.sh

machine:
	./setup-machine.sh
	rm ~/.gitconfig
	cp ~/.gitconfig.personal ~/.gitconfig
