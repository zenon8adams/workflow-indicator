
FISH_SHELL_DESTINATION=~/.config/fish/functions

all:

install:
	@echo "Installing..."
	@install fish_prompt.fish $(FISH_SHELL_DESTINATION)
	@echo "Done!"

.PHONY:	install
