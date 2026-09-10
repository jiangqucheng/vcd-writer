
TOP_DIR=..
sinclude $(TOP_DIR)/make.config.mak

EXES = $(BIN_DIR)/vcd_writer 
LIBS = $(BIN_DIR)/libvcd_writer.so
TARGETS=$(OBJS) $(EXES) $(LIBS)

USING_OPTIMIZE= 
# CXX_FLAGS+= --gpu-architecture=compute_37 --gpu-code=sm_37 
# need these flag to compile shared lib.
CXX_FLAGS+= -shared-libgcc -fPIC   
LINK_FLAGS=$(CXX_FLAGS) 

sinclude $(TOP_DIR)/make.func.mak

.PHONY += BEFORE_ANY

