CONFIGS = brew nvm git linearmouse neovim sdkman wezterm ghostty vscodium zsh

.PHONY: all
all:
	for config in $(CONFIGS); do \
		(cd $$config && $(MAKE)); \
	done

.PHONY: unlock
unlock:
	for config in $(CONFIGS); do \
		(cd $$config && $(MAKE) unlock); \
	done
