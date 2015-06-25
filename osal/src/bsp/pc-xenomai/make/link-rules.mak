
###############################################################################
# File: link-rules.mak
#
# Purpose:
#   Makefile for linking code and producing an executable image.
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
## Linker flags that are needed
##
LDFLAGS = -fPIC -lrt $(XENO_POSIX_LIBS)

##
## Libraries to link in
## Cygwin cannot use the -lrt switch
## Older versions of linux may not have this as well.
##
OSTYPE := $(shell uname -s)
ifeq ($(OSTYPE),Linux)
  LIBS = -lpthread -lrt -ldl
else
  LIBS = -lpthread  -ldl
endif


##
## OSAL Core Link Rule
## 
$(APPTARGET).$(APP_EXT): $(OBJS)
	$(COMPILER) $(DEBUG_FLAGS) -o $(APPTARGET).$(APP_EXT) $(OBJS) $(CORE_OBJS) $(LDFLAGS) $(LIBS)
	

