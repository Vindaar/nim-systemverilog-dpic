# Time-stamp: <2019-04-26 15:05:09 kmodi>
# Author    : Kaushal Modi

FILES   = tb.sv
DEFINES	= DEFINE_PLACEHOLDER
# DSEM2009, DSEMEL: Don't keep on bugging by telling that SV 2009 is
#     being used. I know it already.
# SPDUSD: Don't warn about unused include dirs.
NOWARNS = -nowarn DSEM2009 -nowarn DSEMEL -nowarn SPDUSD
OPTIONS =

# Subdirs contains a list of all directories containing a "Makefile".
SUBDIRS = $(shell find . -name "Makefile" | sed 's|/Makefile||')

ARCH ?= 64
ifeq ($(ARCH), 64)
	NIM_ARCH_FLAGS :=
	NC_ARCH_FLAGS := -64bit
	GCC_ARCH_FLAG := -m64
else
	NIM_ARCH_FLAGS := --cpu:i386 --passC:-m32 --passL:-m32
	NC_ARCH_FLAGS :=
	GCC_ARCH_FLAG := -m32
endif

NIM_GC ?=
NIM_DEFINES =

.PHONY: clean libdpi nc clibdpi $(SUBDIRS) all

clean:
	rm -rf *~ core simv* urg* *.log *.history \#*.* *.dump .simvision/ waves.shm/ \
	core.* simv* csrc* *.tmp *.vpd *.key log temp .vcs* *.txt DVE* *~ \
	INCA_libs xcelium.d *.so *.o ./.nimcache

# libdpi.nim -> libdpi.c -> libdpi.so
# --gc:none is needed else Nim tries to free memory allocated for
# arrays and stuff by the simulator on SV side.
# https://irclogs.nim-lang.org/21-01-2019.html#17:16:39
libdpi:
	@find . \( -name libdpi.o -o -name libdpi.so \) -delete
	nim c --out:libdpi.so --app:lib --nimcache:./.nimcache $(NIM_ARCH_FLAGS) $(NIM_GC) --hint[Processing]:off $(NIM_DEFINES) libdpi.nim

nc:
	xrun -sv $(NC_ARCH_FLAGS) \
	-timescale 1ns/10ps \
	+define+SHM_DUMP -debug \
	+define+$(DEFINES) \
	$(FILES) \
	+incdir+./ \
	$(NOWARNS) \
	$(OPTIONS)

# libdpi.c -> libdpi.so
# -I$(XCELIUM_ROOT)/../include for "svdpi.h"
clibdpi:
	@find . \( -name libdpi.o -o -name libdpi.so \) -delete
	gcc -c -fPIC -I$(XCELIUM_ROOT)/../include libdpi.c $(GCC_ARCH_FLAG) -o libdpi.o
	gcc -shared -Wl,-soname,libdpi.so $(GCC_ARCH_FLAG) -o libdpi.so libdpi.o
	@rm -f libdpi.o

# libdpi.cpp -> libdpi.so
# -I$(XCELIUM_ROOT)/../include for "svdpi.h"
cpplibdpi:
	@find . \( -name libdpi.o -o -name libdpi.so \) -delete
	g++ -c -fPIC -I$(XCELIUM_ROOT)/../include libdpi.cpp $(GCC_ARCH_FLAG) -o libdpi.o
	g++ -shared -Wl,-soname,libdpi.so $(GCC_ARCH_FLAG) -o libdpi.so libdpi.o
	@rm -f libdpi.o

$(SUBDIRS):
	$(MAKE) -C $@

all: $(SUBDIRS)


# Run "make ARCH=32" to build 32-bit libdpi.so and run 32-bit xrun.
# Run "make" to build 64-bit libdpi.so and run 64-bit xrun.
