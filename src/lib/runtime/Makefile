SRCDIR := src
OBJDIR := obj
BINDIR := bin
LIBCOMMONDIR := ../common

CC65TARGET = c64

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)

# The runtime is split into a core and packages (see src/asminc/rtpkg.inc
# and mkruntime.py). Every file name ends with the ABI version.
ABI := $(shell sed -n 's/^RT_ABI_VERSION *= *\([0-9]*\).*/\1/p' ../../asminc/asm.inc)
COREFILE := $(BINTARGETDIR)/core$(ABI)
RTFILES := $(COREFILE) $(BINTARGETDIR)/runtime$(ABI)
RTFILES += $(BINTARGETDIR)/dynarrays$(ABI)a
RTFILES += $(addprefix $(BINTARGETDIR)/files$(ABI),a b)
RTFILES += $(addprefix $(BINTARGETDIR)/trig$(ABI),a b c d)

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D RUNTIME -D __MEGA65__
else
ASFLAGS = -I ../../asminc -D RUNTIME
endif

SOURCES := $(wildcard $(SRCDIR)/*.s)

SOURCES += $(LIBCOMMONDIR)/int8.s
SOURCES += $(LIBCOMMONDIR)/int8add.s
SOURCES += $(LIBCOMMONDIR)/int8mult.s
SOURCES += $(LIBCOMMONDIR)/int8sub.s
SOURCES += $(LIBCOMMONDIR)/int16add.s
SOURCES += $(LIBCOMMONDIR)/int16comp.s
SOURCES += $(LIBCOMMONDIR)/int16mult.s
SOURCES += $(LIBCOMMONDIR)/int16sub.s
SOURCES += $(LIBCOMMONDIR)/int32add.s
SOURCES += $(LIBCOMMONDIR)/int32comp.s
SOURCES += $(LIBCOMMONDIR)/int32mult.s
SOURCES += $(LIBCOMMONDIR)/int32sqr.s
SOURCES += $(LIBCOMMONDIR)/int32sub.s
SOURCES += $(LIBCOMMONDIR)/uint8div.s
SOURCES += $(LIBCOMMONDIR)/uint16div.s
SOURCES += $(LIBCOMMONDIR)/uint16mult.s
SOURCES += $(LIBCOMMONDIR)/uint32comp.s
SOURCES += $(LIBCOMMONDIR)/uint32mult.s

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

# The packages, in package order, and the jump table, which is linked
# separately into the core and the full runtime
PKGOBJECTS := $(addprefix $(OBJTARGETDIR)/,dynarray.o fileops.o trig.o)
JMPTBLOBJ := $(OBJTARGETDIR)/jmptbl.o
JMPTBLFULLOBJ := $(OBJTARGETDIR)/jmptblfull.o
# The header of the dynamic runtime, linked only into runtimeN
RTHDROBJ := $(OBJTARGETDIR)/rthdr.o
COREOBJECTS := $(filter-out $(PKGOBJECTS) $(JMPTBLOBJ) $(RTHDROBJ),$(OBJECTS))

DEPENDS := $(OBJECTS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(COREFILE)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

vpath %.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

# The jump table of the full runtime points at the packages' routines
$(JMPTBLFULLOBJ): $(SRCDIR)/jmptbl.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -D FULLRT $(subst jmptbl.,jmptblfull.,$(DEPFLAGS)) -o $@ $<
	$(FIXDEP)

# mkruntime.py writes every runtime file in one run
$(COREFILE): $(OBJECTS) $(JMPTBLFULLOBJ) mkruntime.py ../../asminc/asm.inc | $(BINTARGETDIR)
	python3 mkruntime.py --asm-inc ../../asminc/asm.inc \
		--objdir $(OBJTARGETDIR) --bindir $(BINTARGETDIR) --map runtime.map \
		--jmptbl $(JMPTBLOBJ) --jmptbl-full $(JMPTBLFULLOBJ) \
		--rthdr $(RTHDROBJ) --pkg $(PKGOBJECTS) $(COREOBJECTS)

clean:
	$(RM) $(OBJECTS) $(JMPTBLFULLOBJ)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) -r $(OBJTARGETDIR)/rtlink
	$(RM) $(BINTARGETDIR)/*

-include $(DEPENDS)
