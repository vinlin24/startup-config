CC = gcc
CFLAGS = -Wall -Wextra -pedantic

ifdef DEBUG
	CFLAGS += -Og -g3
else
	CFLAGS += -O3
endif

BIN_DIRECTORY = /c/bin

all:
	@echo >&2 Specify a make target.
	@exit 1

mock:

branch: prompt/branch_state
prompt/branch_state: prompt/branch_state.c prompt/color.h

venv: prompt/venv_state
prompt/venv_state: prompt/venv_state.c prompt/color.h prompt/vector.c prompt/vector.h

# For testing the vector helper struct.
vector: prompt/vector
prompt/vector: prompt/test_vector.c prompt/vector.c prompt/vector.h

clean:
	rm -rf *.exe *.o __pycache__ prompt/*.exe prompt/*.o prompt/__pycache__

copy:
	-cp -u *.exe prompt/*.exe $(BIN_DIRECTORY)
	@echo
	-ls $(BIN_DIRECTORY)

.PHONY: clean copy
