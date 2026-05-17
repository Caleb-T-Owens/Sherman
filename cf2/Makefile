CC = clang
CFLAGS = -std=c23 -Wall -Wextra -Wpedantic

main: main.o
	$(CC) $(CFLAGS) main.o -o main

main.o: main.c $(ARRAY)
	$(CC) $(CFLAGS) -c main.c -o main.o

# Dependnecies for different files
ARRAY = array.h
