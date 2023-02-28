CC = gcc
CFLAGS = -Wall -Wextra -pedantic -O3

BIN_DIRECTORY = /c/bin

all:
	@echo >&2 Specify a make target.
	@exit 1

mock:

branch_state:

clean:
	rm -rf *.o __pycache__ mock

move:
	cp *.exe $(BIN_DIRECTORY)

.PHONY: clean move
