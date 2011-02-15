CXX = g++
CXXFLAGS = -g -Wall

OBJS = ndame.o
TARGET = dame

$(TARGET): $(OBJS)
	$(CXX) -o $(TARGET) $(OBJS)

all: $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)
 
%.o: $(SRCDIR)/%.cpp
	$(CXX) $(CCXFLAGS) -c $<
