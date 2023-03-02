CXX = g++
CXXFLAGS = -Wall -Wextra -pedantic
LDFLAGS = -lstdc++fs

# Supply the DEBUG macro (any value) to compile with debugging information.
# Otherwise, the default option of maximum optimization is used.
ifdef DEBUG
	CXXFLAGS += -Og -g3
else
	CXXFLAGS += -O3
endif

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
