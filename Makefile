CC = gcc
CFLAGS = -Wall -Wextra -pedantic -O3

BIN_DIRECTORY = /c/bin

all:
	@echo >&2 Specify a make target.
	@exit 1

mock:

branch: prompt/branch_state

venv: prompt/venv_state

prompt/branch_state: prompt/branch_state.c prompt/color.h

prompt/venv_state: prompt/venv_state.c prompt/color.h

clean:
	rm -rf *.exe *.o __pycache__ prompt/*.exe prompt/*.o prompt/__pycache__

copy:
	cp *.exe prompt/*.exe $(BIN_DIRECTORY)

.PHONY: clean copy
