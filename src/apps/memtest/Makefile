BINDIR := bin
OBJDIR := obj
SRCDIR := src

PROGRAM := memtest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
PRGFILE = $(BINTARGETDIR)/memtest

BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(OBJTARGETDIR)/testresult.o

# The coverage build (see cov/mkcov.py). It runs the same tests against an
# instrumented copy of memheap.s and reports which lines never ran.
MEMHEAP := ../../lib/asmlib/src/memheap.s
COVDIR := $(OBJTARGETDIR)/cov
COVSRC := $(COVDIR)/memheap_cov.s
COVMAP := $(COVDIR)/memheap_cov.map
COVPRG := $(BINTARGETDIR)/memtestcov
COVD81 := $(BINTARGETDIR)/memtestcov.d81
COVBIN := $(BINTARGETDIR)/memtest.cov
COVOBJECTS := $(COVDIR)/main.o $(filter-out $(OBJTARGETDIR)/main.o,$(OBJECTS))
COVOBJECTS += $(COVDIR)/memheap_cov.o $(COVDIR)/covshim.o $(COVDIR)/covpatch.o
DEPENDS := $(sort $(OBJECTS:.o=.d) $(COVOBJECTS:.o=.d))
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(COVDIR): | $(OBJTARGETDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

include ../debug.mk

vpath %.s $(SRCDIR) ../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C memtest.cfg $(OBJECTS)

$(D81FILE): $(BINFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) memtest,prg \
	-write $(ASMLIB) asm.lib,prg

$(COVSRC) $(COVMAP): $(MEMHEAP) cov/mkcov.py | $(COVDIR)
	python3 cov/mkcov.py $(MEMHEAP) $(COVSRC) $(COVMAP)

# The tests need the memory checks (asmlib MEMCHECK=1), so the instrumented
# copy has them too. A debug build already defines __DEBUG__.
$(COVDIR)/memheap_cov.o: $(COVSRC)
	ca65 $(ASFLAGS) $(if $(filter 1,$(DEBUG)),,-D __DEBUG__) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(COVDIR)/main.o: $(SRCDIR)/main.s $(FLAGSFILE) | $(COVDIR)
	ca65 $(ASFLAGS) -D COVERAGE $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(COVDIR)/covshim.o: cov/covshim.s | $(COVDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(COVDIR)/covpatch.o: cov/covpatch.s | $(COVDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(COVPRG): $(COVOBJECTS) | $(BINTARGETDIR)
	ld65 -o $(COVPRG) -C memtest.cfg $(COVOBJECTS)

clean:
	$(RM) $(D81FILE) $(PRGFILE) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) -r $(COVDIR)
	$(RM) $(COVPRG) $(COVD81) $(COVBIN)

test:
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE)

# Like test, coverage runs a debug build.
coverage:
	$(MAKE) TARGET=$(TARGET) DEBUG=1 covrun

# The disk is made fresh for each run because the test saves the coverage
# map to it.
covrun: $(COVPRG) $(COVMAP)
	$(RM) $(COVD81) $(COVBIN)
	c1541 -format memtestcov,8a d81 $(COVD81) \
	-write $(COVPRG) memtest,prg \
	-write $(ASMLIB) asm.lib,prg
	../testcommon/runtest.sh memtestcov $(COVPRG) $(COVD81)
	c1541 -attach $(COVD81) -read memtest.cov $(COVBIN)
	python3 cov/covreport.py $(COVMAP) $(COVBIN)

.PHONY: all clean test coverage covrun

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

-include $(DEPENDS)
