BINDIR := bin
OBJDIR := obj
SRCDIR := src

PROGRAM := membuftest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__
# make test TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m" runs only those tests.
# main.o doesn't track it, so remove obj/$(TARGET)/main.o when changing it.
TESTSEL ?=

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
PRGFILE = $(BINTARGETDIR)/$(PROGRAM)

BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(OBJTARGETDIR)/testresult.o

# The coverage build. make coverage runs the tests against instrumented
# copies of the membuf routines (editortest's cov/mkcov.py) and lists the
# lines that never ran in bin/$(TARGET)/coverage.txt. Like test, it needs
# asmlib built with MEMCHECK=1.
#
# The copies are linked into the test program. The names in asmlib's jump
# table get a cov_ prefix so they don't clash with asmlib.inc, and
# cov/covpatch.s points the jump table at them. The map is COVSIZE bytes at
# COVMAP, above the program.
MEMBUFDIR := ../../lib/asmlib/src/membuf
MEMBUFSRC := $(wildcard $(MEMBUFDIR)/*.s)
MKCOV := ../editortest/cov/mkcov.py
COVREPORT := ../editortest/cov/covreport.py
COVMAP := 32768
COVSIZE := 512
RENAMED := allocMemBuf|freeMemBuf|getMemBufPos|readFromMemBuf|setMemBufPos|writeToMemBuf|isMemBufAtEnd
COVDIR := $(OBJTARGETDIR)/cov
COVRAW := $(COVDIR)/raw
COVMBOBJS := $(addprefix $(COVDIR)/,$(notdir $(MEMBUFSRC:.s=.o)))
COVOBJECTS := $(COVDIR)/main.o $(COVDIR)/covpatch.o $(COVMBOBJS)
COVOBJECTS += $(filter-out $(OBJTARGETDIR)/main.o,$(OBJECTS))
COVPRG := $(BINTARGETDIR)/$(PROGRAM)cov
COVD81 := $(BINTARGETDIR)/$(PROGRAM)cov.d81
COVBIN := $(BINTARGETDIR)/membuf.cov
COVLIST := $(BINTARGETDIR)/coverage.txt

DEPENDS := $(OBJECTS:.o=.d)
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

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

include ../debug.mk

vpath %.s $(SRCDIR) ../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(TESTSEL) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C $(PROGRAM).cfg $(OBJECTS)

$(D81FILE): $(BINFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) $(PROGRAM),prg \
	-write $(ASMLIB) asm.lib,prg

# mkcov writes the instrumented copies to raw/, then the jump table's names
# are renamed
$(COVDIR)/stamp: $(MEMBUFSRC) $(MKCOV)
	mkdir -p $(COVRAW)
	python3 $(MKCOV) -m $(COVSIZE) $(COVRAW) $(COVDIR)/membuf.map \
	$(MEMBUFSRC)
	for f in $(notdir $(MEMBUFSRC)); do \
	sed -E 's/\b($(RENAMED))\b/cov_\1/g' $(COVRAW)/$$f > $(COVDIR)/$$f \
	|| exit 1; \
	done
	touch $@

$(COVMBOBJS): $(COVDIR)/stamp
	ca65 $(ASFLAGS) -D COVMAP=$(COVMAP) -o $@ $(@:.o=.s)

$(COVDIR)/main.o: $(SRCDIR)/main.s $(FLAGSFILE)
	mkdir -p $(COVDIR)
	ca65 $(ASFLAGS) -D COVERAGE -o $@ $<

$(COVDIR)/covpatch.o: cov/covpatch.s
	mkdir -p $(COVDIR)
	ca65 $(ASFLAGS) -D COVMAP=$(COVMAP) -D COVSIZE=$(COVSIZE) -o $@ $<

$(COVPRG): $(COVOBJECTS) | $(BINTARGETDIR)
	ld65 -o $(COVPRG) -C $(PROGRAM).cfg $(COVOBJECTS)

clean:
	$(RM) $(D81FILE) $(PRGFILE) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) -r $(COVDIR)
	$(RM) $(COVPRG) $(COVD81) $(COVBIN) $(COVLIST)

test:
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE)

# Like test, coverage runs a debug build. The copies are made fresh each
# time: they don't track the includes.
coverage:
	$(RM) -r $(COVDIR)
	$(RM) $(COVBIN)
	$(MAKE) TARGET=$(TARGET) DEBUG=1 covrun

# The disk is made fresh for each run because the test saves the map to it
covrun: $(COVPRG)
	$(RM) $(COVD81)
	c1541 -format $(PROGRAM)cov,8a d81 $(COVD81) \
	-write $(COVPRG) $(PROGRAM),prg \
	-write $(ASMLIB) asm.lib,prg
	../testcommon/runtest.sh $(PROGRAM)cov $(COVPRG) $(COVD81)
	c1541 -attach $(COVD81) -read membuf.cov $(COVBIN)
	python3 $(COVREPORT) $(COVLIST) -m $(COVDIR)/membuf.map $(COVBIN)

.PHONY: all clean test coverage covrun

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

-include $(DEPENDS)
