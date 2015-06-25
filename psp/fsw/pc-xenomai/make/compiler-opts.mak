##############################################################################
## compiler-opts.mak - compiler definitions and options for building the cFE 
##
## Target: x86 PC Linux
##
## Modifications:
##
###############################################################################

##
## Xenomai Flags
##
XENO_DESTDIR:=/home/bryan/build_xen/tmprootfs
XENO_CONFIG:=$(XENO_DESTDIR)/usr/xenomai/bin/xeno-config
XENO_POSIX_CFLAGS:=$(shell DESTDIR=$(XENO_DESTDIR) $(XENO_CONFIG) --skin=posix --cflags)

## 
## Warning Level Configuration
##
# WARNINGS=-Wall -ansi -pedantic -Wstrict-prototypes
WARNINGS=-Wall -Wstrict-prototypes

## 
## Host OS Include Paths ( be sure to put the -I switch in front of each directory )
##
SYSINCS=

##
## Target Defines for the OS, Hardware Arch, etc..
##
TARGET_DEFS=-D__ix86__ -D_ix86_ -D_LINUX_OS_  -D$(OS) -DX86PC -DBUILD=$(BUILD) -D_REENTRANT -D _EMBED_  

## 
## Endian Defines
##
ENDIAN_DEFS=-D_EL -DENDIAN=_EL -DSOFTWARE_LITTLE_BIT_ORDER 

##
## Compiler Architecture Switches
## 
ARCH_OPTS = -fPIC

##
## Application specific compiler switches 
##
ifeq ($(BUILD_TYPE),CFE_APP)
   APP_COPTS= 
   APP_ASOPTS=
else
   APP_COPTS=
   APP_ASOPTS=
endif

##
## Extra Cflags for Assembly listings, etc.
##
LIST_OPTS = 

##
## gcc options for dependancy generation
## 
COPTS_D = $(APP_COPTS) $(ENDIAN_DEFS) $(TARGET_DEFS) $(ARCH_OPTS) $(SYSINCS) $(WARNINGS)

## 
## General gcc options that apply to compiling and dependency generation.
##
COPTS=$(LIST_OPTS) $(COPTS_D) $(XENO_POSIX_CFLAGS)

##
## Extra defines and switches for assembly code
##
ASOPTS = $(APP_ASOPTS) -P -xassembler-with-cpp 

##---------------------------------------------------------
## Application file extention type
## This is the defined application extention.
## Known extentions: Mac OS X: .bundle, Linux: .so, RTEMS:
##   .s3r, vxWorks: .o etc.. 
##---------------------------------------------------------
APP_EXT = so

#################################################################################
## Host Development System and Toolchain defintions
##

##
## Host OS utils
##
RM=rm -f
CP=cp

##
## Compiler tools
##
COMPILER=arm-xilinx-linux-gnueabi-gcc
ASSEMBLER=arm-xilinx-linux-gnueabi-as
LINKER=arm-xilinx-linux-gnueabi-ld
AR=arm-xilinx-linux-gnueabi-ar
NM=arm-xilinx-linux-gnueabi-nm
SIZE=arm-xilinx-linux-gnueabi-size
OBJCOPY=arm-xilinx-linux-gnueabi-objcopy
OBJDUMP=arm-xilinx-linux-gnueabi-objdump
TABLE_BIN = elf2cfetbl