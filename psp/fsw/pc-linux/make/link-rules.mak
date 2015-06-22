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
## Executable target. This is target specific
##
EXE_TARGET=core-linux.bin

CORE_INSTALL_FILES = $(EXE_TARGET)


##
## Linker flags that are needed
##
LDFLAGS = -fPIC -Wl,-export-dynamic -lrt

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
	$(COMPILER) -fPIC -shared -o $@ $(OBJS) 
