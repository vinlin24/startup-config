CC = gcc
CFLAGS = -Wall -Wextra -pedantic -O3

BIN_DIRECTORY = /c/bin

all: mock

clean:
	rm -rf *.o __pycache__ mock

move:
	cp *.exe $(BIN_DIRECTORY)

.PHONY: clean move
