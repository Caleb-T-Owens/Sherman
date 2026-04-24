CC=gcc -Wall -Wpedantic

ods: ods.o error.o term.o
	$(CC) ods.o error.o term.o -o ods

ods.o: ods.c
	$(CC) $(CFLAGS) -c ods.c -o ods.o

error.o: error.c error.h
	$(CC) $(CFLAGS) -c error.c -o error.o

term.o: term.c term.h
	$(CC) $(CFLAGS) -c term.c -o term.o

.PHONY: clean
clean:
	rm *.o
	rm ods

