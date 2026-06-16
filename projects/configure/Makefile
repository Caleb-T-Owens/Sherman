CC ?= cc
CFLAGS ?= -Wall -Wextra -O2
PREFIX ?= $(HOME)/Sherman/bin

configure: configure.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: install
install: configure
	mkdir -p $(PREFIX)
	cp configure $(PREFIX)/configure

.PHONY: clean
clean:
	rm -f configure

.PHONY: all
all: configure
