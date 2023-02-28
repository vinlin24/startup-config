CC = gcc
CFLAGS = -Wall -Wextra -pedantic -O3

BIN_DIRECTORY = /c/bin

all:
	@echo >&2 Specify a make target.
	@exit 1

mock:

branch_state:

clean:
	rm -rf *.exe *.o __pycache__

copy:
	cp *.exe $(BIN_DIRECTORY)

.PHONY: clean copy
