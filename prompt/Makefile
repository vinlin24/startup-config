CC = gcc
CFLAGS = -Wall -Wextra -pedantic -O3

TARGET = prompt

all: $(TARGET)

$(TARGET): prompt.o branch_state.o

prompt.o: prompt.c

branch_state.o: branch_state.c branch_state.h color.h

clean:
	rm -rf *.exe *.o __pycache__

.PHONY: clean
