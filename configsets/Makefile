CONFIGS = debian/dwm debian/dmenu debian/bash
ACTIONS =

.PHONY: all
all:
	for config in $(CONFIGS); do \
		(cd $$config && $(MAKE)); \
	done
	for action in $(ACTIONS); do \
		(cd $$action && $(MAKE)); \
	done

.PHONY: unlock
unlock:
	rm $(wildcard */make-lock */*/make-lock */*/*/make-lock)

