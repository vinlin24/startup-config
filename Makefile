CC = gcc
CXX = g++
CFLAGS = -Wall -Wextra -pedantic
LDFLAGS = -lstdc++fs

ifdef DEBUG
	CFLAGS += -Og -g3
else
	CFLAGS += -O3
endif

CXXFLAGS = -std=c++17 $(CFLAGS)

BIN_DIRECTORY = /c/bin

all:
	@echo >&2 Specify a make target.
	@exit 1

mock:

.PHONY: branch
branch: prompt/branch_state
prompt/branch_state: prompt/branch_state.o
prompt/branch_state.o: prompt/branch_state.c prompt/color.h

.PHONY: venv
venv: prompt/venv_state
prompt/venv_state: prompt/venv_state.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)
prompt/venv_state.o: prompt/venv_state.cpp prompt/color.h
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf *.exe *.o __pycache__ prompt/*.exe prompt/*.o prompt/__pycache__

copy:
	-cp -u *.exe prompt/*.exe $(BIN_DIRECTORY)
	@echo
	-ls $(BIN_DIRECTORY)

.PHONY: clean copy
