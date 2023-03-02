CXX = g++
CXXFLAGS = -Wall -Wextra -pedantic -O3
LDFLAGS = -lstdc++fs

TARGET = prompt

# Use .cpp files instead of .c files.
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

all: $(TARGET)

$(TARGET): prompt.o branch_state.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

prompt.o: prompt.cpp

branch_state.o: branch_state.cpp branch_state.hpp color.h

clean:
	rm -rf *.exe *.o __pycache__

.PHONY: clean
