BINDIR := bin
OBJDIR := obj
SRCDIR := src
TESTSDIR := tests
PETSCIIDIR := petscii
TOKENIZERDIR := ../../overlays/tokenizerasm
ICODEDIR := ../../overlays/icodeasm
PARSERDIR := ../../overlays/parserasm
DUMPICODEDIR := ../../overlays/dumpicode
RESOLVERDIR := ../../overlays/resolverasm
TYPECHECKDIR := ../../overlays/typecheckasm
TPUDIR := ../../overlays/tpuasm
ASMLIBDIR := ../../lib/asmlib
# icodetest's loaders and pipeline routines, and compilerasm's initTpu and
# tokenizeAndParseUnits, which loads a unit from its TPU (tpuload.s)
ICODETESTSRC := ../icodetest/src
COMPILERSRC := ../compilerasm/src
HDRSHAREDDIR := ../../shared/hdr

PROGRAM := tputest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
ICODE = ../../overlays/icodeasm/bin/$(TARGET)/icode
DUMPICODE = ../../overlays/dumpicode/bin/$(TARGET)/dumpicode
RESOLVER = ../../overlays/resolverasm/bin/$(TARGET)/resolver
TYPECHECK = ../../overlays/typecheckasm/bin/$(TARGET)/typecheck
TPU = ../../overlays/tpuasm/bin/$(TARGET)/tpu
PRGFILE = $(BINTARGETDIR)/tputest
SYSTEMPAS = ../../lib/system/system.pas

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(ICODE)
BINFILES += $(DUMPICODE)
BINFILES += $(RESOLVER)
BINFILES += $(TYPECHECK)
BINFILES += $(TPU)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

SHARED := freeUnits initdumpicode initicode initlib initparser \
	initresolver inittokenizer inittypecheck loadaddr loadfile logerror \
	m65hdr timer
SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addprefix $(OBJTARGETDIR)/,$(addsuffix .o,$(SHARED)))
OBJECTS += $(OBJTARGETDIR)/inittpu.o $(OBJTARGETDIR)/tokenizeAndParseUnits.o
OBJECTS += $(OBJTARGETDIR)/hdrload.o $(OBJTARGETDIR)/hdrtables.o
OBJECTS += $(OBJTARGETDIR)/testresult.o
DEPENDS := $(OBJECTS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

TXTFILES := errormsgs.petscii system.petscii

TESTS := $(wildcard $(TESTSDIR)/*.pas)
TXTFILES += $(patsubst $(TESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(TESTS))
comma := ,

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

system.petscii: $(SYSTEMPAS)
	dos2unix < $(SYSTEMPAS) | petcat -w2 -text -o system.petscii

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(PETSCIIDIR):
	mkdir -p $@

$(PARSER): FORCE
	cd $(PARSERDIR) && $(MAKE) TARGET=$(TARGET)

$(RESOLVER): FORCE
	cd $(RESOLVERDIR) && $(MAKE) TARGET=$(TARGET)

$(TYPECHECK): FORCE
	cd $(TYPECHECKDIR) && $(MAKE) TARGET=$(TARGET)

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(ICODE): FORCE
	cd $(ICODEDIR) && $(MAKE) TARGET=$(TARGET)

$(DUMPICODE): FORCE
	cd $(DUMPICODEDIR) && $(MAKE) TARGET=$(TARGET)

$(TPU): FORCE
	cd $(TPUDIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

include ../debug.mk

vpath %.s $(SRCDIR) $(ICODETESTSRC) $(COMPILERSRC) $(HDRSHAREDDIR) \
	../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

# icodetest has its own, which vpath would find first
$(OBJTARGETDIR)/tokenizeAndParseUnits.o: \
	$(COMPILERSRC)/tokenizeAndParseUnits.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

vpath %.pas $(TESTSDIR)
$(PETSCIIDIR)/%.pas: %.pas | $(PETSCIIDIR)
	dos2unix < $< | petcat -w2 -text -o $@

# TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m" runs only those tests. A first
# test after the last runs none. SAVEDUMP=1 writes each test's dump to the
# disk in place of comparing it (see savedump). The settings are kept in a
# file so a change rebuilds the objects.
TESTSEL ?=
SAVEDUMP ?=
TESTSFILE := $(OBJTARGETDIR)/testsel

$(TESTSFILE): FORCE | $(OBJTARGETDIR)
	@echo "$(TESTSEL) $(SAVEDUMP)" | cmp -s - $@ || \
	echo "$(TESTSEL) $(SAVEDUMP)" > $@

$(OBJTARGETDIR)/runtests.o: ASFLAGS += $(TESTSEL)
$(OBJTARGETDIR)/runtest.o: ASFLAGS += $(if $(SAVEDUMP),-D SAVEDUMP)
$(OBJTARGETDIR)/runtests.o $(OBJTARGETDIR)/runtest.o: $(TESTSFILE)

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C tputest.cfg $(OBJECTS)

FORCE:

# Every .pas file in tests goes on the disk. The tests write their TPUs
# to it, so it is made fresh for each run.
$(D81FILE): $(BINFILES) $(TXTFILES)
	$(RM) $(D81FILE)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) tputest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(ICODE) icode,prg \
	-write $(PARSER) parser,prg \
	-write $(RESOLVER) resolver,prg \
	-write $(TYPECHECK) typecheck,prg \
	-write $(DUMPICODE) dumpicode,prg \
	-write $(TPU) tpu,prg \
	-write $(ASMLIB) asm.lib,prg \
	$(foreach f,$(notdir $(TESTS)), \
	-write $(PETSCIIDIR)/$(f) $(f)$(comma)seq) \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write system.petscii system.pas,seq

clean:
	$(RM) $(TXTFILES)
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) $(D81FILE)

test:
	$(RM) $(D81FILE)
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE)

# Writes the dump of each test TESTSEL selects to bin/$(TARGET)/dumpN.txt,
# in ASCII, for writing a new test's header. Check it before using it. The
# objects are rebuilt without SAVEDUMP by the next make test.
savedump:
	$(RM) $(D81FILE)
	$(MAKE) TARGET=$(TARGET) DEBUG=1 SAVEDUMP=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE)
	cd $(BINTARGETDIR) && for f in $$(c1541 -attach $(PROGRAM).d81 -list | \
	sed -n 's/.*"\(dump[0-9]*\)".*/\1/p'); do \
	c1541 -attach $(PROGRAM).d81 -read $$f$(comma)s $$f.seq && \
	petcat -text -o $$f.txt -- $$f.seq && rm -f $$f.seq; done

.PHONY: test savedump

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

-include $(DEPENDS)
