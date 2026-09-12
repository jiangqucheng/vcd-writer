# Kept in sync with CMakeLists.txt: same library name, same version and
# soname, same warning flags. Either build system can be used; they write
# to different directories (make -> lib/ and obj/, cmake -> build/) so
# they do not collide.

# Mirrors project(vcdwriter VERSION ...) in CMakeLists.txt
PROJECT_VERSION       := 1.0.0
PROJECT_VERSION_MAJOR := 1

# Mirrors target_compile_features(... cxx_std_11), which sets a *minimum*
# rather than pinning the standard. Left empty the compiler default is used,
# exactly as under CMake. Override to build at a specific standard, e.g.
#   make CXXSTD=c++11
CXXSTD ?=

# Mirrors -DVCDWRITER_WARNINGS_AS_ERRORS=ON
WARNINGS_AS_ERRORS ?= 0

SRC_DIR  := src
INC_DIR  := include
TEST_DIR := test
LIB_DIR  := lib
OBJ_DIR  := obj

SOURCES  := $(wildcard $(SRC_DIR)/*.cpp)
OBJECTS  := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(SOURCES))
TEST_SRC := $(TEST_DIR)/vcd_writer_tester.cpp
TEST_OBJ := $(OBJ_DIR)/vcd_writer_tester.o
TESTER   := $(TEST_DIR)/vcd_writer_tester
DEPS     := $(OBJECTS:.o=.d) $(TEST_OBJ:.o=.d)

# -MMD -MP regenerate objects when a header they include changes
CPPFLAGS += -I$(INC_DIR) -MMD -MP
CXXFLAGS += -Wall -Wextra -fPIC

ifneq ($(CXXSTD),)
  CXXFLAGS += -std=$(CXXSTD)
endif

ifeq ($(WARNINGS_AS_ERRORS),1)
  CXXFLAGS += -Werror
endif

# Shared-library naming and versioning differ between ELF and Mach-O
STATIC_LIB := $(LIB_DIR)/libvcdwriter.a
ifeq ($(shell uname -s),Darwin)
  SHARED_REAL   := libvcdwriter.$(PROJECT_VERSION).dylib
  SHARED_SONAME := libvcdwriter.$(PROJECT_VERSION_MAJOR).dylib
  SHARED_LINK   := libvcdwriter.dylib
  SHARED_FLAGS  := -dynamiclib -Wl,-install_name,@rpath/$(SHARED_SONAME)
else
  SHARED_REAL   := libvcdwriter.so.$(PROJECT_VERSION)
  SHARED_SONAME := libvcdwriter.so.$(PROJECT_VERSION_MAJOR)
  SHARED_LINK   := libvcdwriter.so
  SHARED_FLAGS  := -shared -Wl,-soname,$(SHARED_SONAME)
endif

.PHONY: all static shared test clean
all: static shared $(TESTER)

static: $(STATIC_LIB)
shared: $(LIB_DIR)/$(SHARED_REAL)

$(OBJ_DIR) $(LIB_DIR):
	@mkdir -p $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp | $(OBJ_DIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(TEST_OBJ): $(TEST_SRC) | $(OBJ_DIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(STATIC_LIB): $(OBJECTS) | $(LIB_DIR)
	$(AR) rcs $@ $^

$(LIB_DIR)/$(SHARED_REAL): $(OBJECTS) | $(LIB_DIR)
	$(CXX) $(SHARED_FLAGS) -o $@ $^
	ln -sf $(SHARED_REAL) $(LIB_DIR)/$(SHARED_SONAME)
	ln -sf $(SHARED_SONAME) $(LIB_DIR)/$(SHARED_LINK)

# Linked against the static library so the tester needs no rpath
$(TESTER): $(TEST_OBJ) $(STATIC_LIB)
	$(CXX) -o $@ $(TEST_OBJ) $(STATIC_LIB)

# Rough equivalent of ctest
test: $(TESTER)
	./$(TESTER)

clean:
	rm -rf $(OBJ_DIR) $(LIB_DIR)
	rm -f $(TESTER) dump.vcd
	rm -f $(SRC_DIR)/*.o $(SRC_DIR)/*.d $(TEST_DIR)/*.o $(TEST_DIR)/*.d

-include $(DEPS)
