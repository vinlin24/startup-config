CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -pedantic -Wno-unknown-pragmas
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

$(TARGET): prompt.o branch_state.o venv_state.o user_path.o subprocess.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

prompt.o: prompt.cpp

branch_state.o: branch_state.cpp branch_state.hpp color.hpp strings.hpp subprocess.o

venv_state.o: venv_state.cpp venv_state.hpp color.hpp strings.hpp subprocess.o

user_path.o: user_path.cpp user_path.hpp color.hpp strings.hpp

subprocess.o: subprocess.cpp subprocess.hpp

clean:
	rm -rf *.exe *.o __pycache__

.PHONY: clean
