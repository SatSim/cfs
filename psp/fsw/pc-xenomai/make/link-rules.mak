###############################################################################
# File: link-rules.mak
#
# Purpose:
#   Makefile for linking code and producing the cFE Core executable image.
#
# History:
#
###############################################################################

##
## Xenomai
##
XENO_DESTDIR:=/home/bryan/build_xen/tmprootfs
XENO_CONFIG:=$(XENO_DESTDIR)/usr/xenomai/bin/xeno-config
XENO_POSIX_LIBS:=$(shell DESTDIR=$(XENO_DESTDIR) $(XENO_CONFIG) --skin=posix --ldflags)

##
## Executable target. This is target specific
##
EXE_TARGET=core-linux.bin

CORE_INSTALL_FILES = $(EXE_TARGET)


##
## Linker flags that are needed
##
LDFLAGS = -fPIC -Wl,-export-dynamic -lrt $(XENO_POSIX_LIBS)

##
## Libraries to link in
##
LIBS =  -lm -lpthread -ldl -lrt
##
## Uncomment the following line to link in C++ standard libs
## LIBS += -lstdc++
## 

##
## cFE Core Link Rule
## 
$(EXE_TARGET): $(CORE_OBJS)
	$(COMPILER) $(DEBUG_FLAGS) -o $(EXE_TARGET) $(CORE_OBJS) $(LDFLAGS) $(LIBS)
	
##
## Application Link Rule
##
$(APPTARGET).$(APP_EXT): $(OBJS)
	$(COMPILER) -fPIC -shared -o $@ $(OBJS) $(XENO_POSIX_LIBS)
