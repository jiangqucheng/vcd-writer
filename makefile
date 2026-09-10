
OBJS = $(patsubst %.cpp,%.o,$(wildcard src/*.cpp))
OBJS_TEST = $(patsubst %.cpp,%.o,$(wildcard test/*.cpp))
EXES = test/vcd_writer_tester
LIBS = lib/libvcd_writer.so
TARGETS=$(OBJS) $(OBJS_TEST) $(EXES) $(LIBS)

INCLUDES = -I include
CXXFLAGS = -Wall -Wextra -Werror -fPIC $(INCLUDES)

.PHONY: all clean
all: $(TARGETS)

lib/libvcd_writer.so: $(OBJS)
	@mkdir -p lib
	$(CXX) -shared -o $@ $^

test/vcd_writer_tester: $(OBJS) $(OBJS_TEST)
	@mkdir -p test
	$(CXX) -o $@ $^

clean:
	rm -f $(TARGETS)
	rm -f test/vcd_writer_tester
	rm -f lib/libvcd_writer.so 
	rm -rf lib bin
