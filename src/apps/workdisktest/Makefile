BINDIR := bin
OBJDIR := obj
SRCDIR := src

PROGRAM := workdisktest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIBDIR := ../../lib/asmlib
WORKDISKDIR := ../../overlays/workdisk
RUNTIMEDIR := ../../lib/runtime
ASMLIB = $(ASMLIBDIR)/bin/$(TARGET)/asmlib
WORKDISK = $(WORKDISKDIR)/bin/$(TARGET)/workdisk
MKTHEMES := ../../shared/mkthemes.py
THEMESTXT := ../../shared/themes.txt

# The runtime files (RTABI, RUNTIME). Only runtimeN goes on the disk.
include $(RUNTIMEDIR)/rtfiles.mk
RUNTIMEN = $(RUNTIMEDIR)/bin/$(TARGET)/runtime$(RTABI)

PRGFILE := $(BINTARGETDIR)/$(PROGRAM).prg
# The system disk (unit 8) and the disk the tests make a work disk of
# (unit 9), which starts blank
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81
WORKD81 := $(BINTARGETDIR)/work.d81
THEMESDAT := $(OBJTARGETDIR)/themes.dat

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES:.s=.o)))
OBJECTS += $(OBJTARGETDIR)/testresult.o
DEPENDS := $(OBJECTS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE) $(WORKD81)

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(WORKDISK): FORCE
	cd $(WORKDISKDIR) && $(MAKE) TARGET=$(TARGET)

$(RUNTIME): FORCE
	cd $(RUNTIMEDIR) && $(MAKE) TARGET=$(TARGET)

$(RUNTIMEN): $(RUNTIME)

$(THEMESDAT): $(THEMESTXT) $(MKTHEMES) | $(OBJTARGETDIR)
	python3 $(MKTHEMES) -o $@ $(THEMESTXT)

include ../debug.mk

vpath %.s $(SRCDIR) ../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(PRGFILE): $(OBJECTS) $(PROGRAM).cfg | $(BINTARGETDIR)
	ld65 -o $@ -C $(PROGRAM).cfg $(OBJECTS)

$(D81FILE): $(PRGFILE) $(ASMLIB) $(WORKDISK) $(RUNTIMEN) $(THEMESDAT)
	$(RM) $@
	c1541 -format $(PROGRAM),8a d81 $@ -write $< $(PROGRAM),prg \
	-write $(ASMLIB) asm.lib,prg -write $(WORKDISK) workdisk,prg \
	-write $(RUNTIMEN) runtime$(RTABI),prg \
	-write $(THEMESDAT) themes.dat,seq

$(WORKD81): | $(BINTARGETDIR)
	c1541 -format work,9a d81 $@

clean:
	$(RM) $(PRGFILE) $(D81FILE) $(WORKD81) $(OBJECTS) $(THEMESDAT)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)

# The disks are made fresh, since the tests change them
test:
	$(RM) $(D81FILE) $(WORKD81)
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE) $(WORKD81)

run: all
	xmega65 -besure -8 $(D81FILE) -9 $(WORKD81)

.PHONY: all clean test run

-include $(DEPENDS)
