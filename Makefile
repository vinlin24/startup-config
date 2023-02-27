CC = gcc
CFLAGS = -Wall -Wextra -pedantic -O3

all: mock

clean:
	rm -rf *.o __pycache__ mock

.PHONY: clean
