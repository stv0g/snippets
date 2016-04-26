CXX = g++
CXXFLAGS = -g -Wall

OBJS = josephus.o
TARGET = josephus

$(TARGET): $(OBJS)
	$(CXX) -o $(TARGET) $(OBJS)

all: $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)
 
%.o: $(SRCDIR)/%.cpp
	$(CXX) $(CCXFLAGS) -c $<
