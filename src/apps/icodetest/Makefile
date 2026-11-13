BINDIR := bin
OBJDIR := obj
SRCDIR := src
TESTSDIR := tests
ERRORTESTSDIR := errortests
PETSCIIDIR := petscii
TOKENIZERDIR := ../../overlays/tokenizerasm
ICODEDIR := ../../overlays/icodeasm
PARSERDIR := ../../overlays/parserasm
SHOWTREEDIR := ../../overlays/showtree
DUMPICODEDIR := ../../overlays/dumpicode
RESOLVERDIR := ../../overlays/resolverasm
TYPECHECKDIR := ../../overlays/typecheckasm
MEMINFODIR := ../../overlays/meminfo
ASMLIBDIR := ../../lib/asmlib

PROGRAM := icodetest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
ICODE = ../../overlays/icodeasm/bin/$(TARGET)/icode
SHOWTREE = ../../overlays/showtree/bin/$(TARGET)/showtree
DUMPICODE = ../../overlays/dumpicode/bin/$(TARGET)/dumpicode
RESOLVER = ../../overlays/resolverasm/bin/$(TARGET)/resolver
TYPECHECK = ../../overlays/typecheckasm/bin/$(TARGET)/typecheck
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
PRGFILE = $(BINTARGETDIR)/icodetest
SYSTEMPAS = ../../lib/system/system.pas

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(ICODE)
BINFILES += $(SHOWTREE)
BINFILES += $(DUMPICODE)
BINFILES += $(RESOLVER)
BINFILES += $(TYPECHECK)
BINFILES += $(MEMINFO)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
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
ERRORTESTS := $(wildcard $(ERRORTESTSDIR)/*.pas)
TXTFILES += $(patsubst $(TESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(TESTS))
TXTFILES += $(patsubst $(ERRORTESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(ERRORTESTS))
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

$(SHOWTREE): FORCE
	cd $(SHOWTREEDIR) && $(MAKE) TARGET=$(TARGET)

$(DUMPICODE): FORCE
	cd $(DUMPICODEDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

include ../debug.mk

vpath %.s $(SRCDIR) ../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

vpath %.pas $(TESTSDIR)
$(PETSCIIDIR)/%.pas: %.pas | $(PETSCIIDIR)
	dos2unix < $< | petcat -w2 -text -o $@

vpath %.pas $(ERRORTESTSDIR)
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
	ld65 -o $(PRGFILE) -C icodetest.cfg $(OBJECTS)

FORCE:

# Makes a disk: $(1) is the D81, $(2) the test program and $(3) the icode
# overlay. Every .pas file in tests goes on it.
define MKDISK
c1541 -format $(PROGRAM),8a d81 $(1) \
	-write $(2) icodetest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(3) icode,prg \
	-write $(PARSER) parser,prg \
	-write $(RESOLVER) resolver,prg \
	-write $(TYPECHECK) typecheck,prg \
	-write $(DUMPICODE) dumpicode,prg \
	-write $(SHOWTREE) showtree,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(ASMLIB) asm.lib,prg \
	$(foreach f,$(notdir $(TESTS) $(ERRORTESTS)), \
	-write $(PETSCIIDIR)/$(f) $(f)$(comma)seq) \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write system.petscii system.pas,seq
endef

$(D81FILE): $(BINFILES) $(TXTFILES)
	$(call MKDISK,$(D81FILE),$(PRGFILE),$(ICODE))

# The coverage build. make coverage runs the tests against instrumented
# copies of the icode overlay (see ../editortest/cov/mkcov.py) and lists
# the lines that never ran in bin/$(TARGET)/coverage.txt. Like test, it
# needs asmlib built with MEMCHECK=1.
#
# The probes make the overlay much bigger, and they don't all fit at once.
# So the files are instrumented in sets (COVFILESn), and the tests run once a
# set. A set's map is COVSIZE bytes at COVMAP, above the test program. A set
# that no longer fits fails to link and must be split.
COVTOOLS := ../editortest/cov
COVMAP := 14848
COVSIZE := 512
COVSETS := 1 2 3 4 5 6
COVSET ?= 1
# Expressions
COVFILES1 := icodeExpr.s getExprType.s getExprTypeKind.s \
	setIcodeUnitsList.s icodeVar.s
# Array initializers, routine calls and loops
COVFILES2 := icodeArrayInit.s icodeRoutineCall.s icodeOper.s \
	icodeRepeatStmt.s icodeWhileStmt.s
# Standard routines, variable declarations and if statements
COVFILES3 := icodeStdRoutineCall.s icodeVariableDeclarations.s \
	icodeIfStmt.s icodeCompExpr.s
# Records, files, case statements, Write and units
COVFILES4 := icodeRecordInit.s icodeFile.s icodeCaseStmt.s \
	icodeWriteWritelnCall.s icodeUnitDeclarations.s icodeUnitRoutines.s
# Literals, values, data, Read and routine declarations
COVFILES5 := addEmbeddedArrayOrRecord.s icodeValue.s \
	addScalarArrayLiterals.s addStringArrayLiterals.s icodeData.s \
	icodeReadReadlnCall.s icodeRoutineDeclaration.s
# Subroutine calls, for loops, math and statements
COVFILES6 := icodeDecIncCall.s icodeDeclaredSubroutineCall.s \
	icodeForLoop.s icodeIntOrRealMath.s icodeLibrarySubroutineCall.s \
	icodeRoutineCleanup.s icodeRoutineDeclarations.s \
	icodeRoutineParamsCleanup.s icodeStmts.s icodeSubroutineCall.s \
	icodeWrite.s

ICODESRCDIR := $(ICODEDIR)/src
ICODESOURCES := $(wildcard $(ICODESRCDIR)/*.s)
COVASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__ \
	-D COVMAP=$(COVMAP)
COVDIR := $(OBJTARGETDIR)/cov$(COVSET)
COVICODEOBJS := $(addprefix $(COVDIR)/, $(notdir $(ICODESOURCES:.s=.o)))
COVICODE := $(COVDIR)/icode
COVPRGDIR := $(OBJTARGETDIR)/cov
COVPRG := $(COVPRGDIR)/$(PROGRAM)
COVPRGOBJS := $(COVPRGDIR)/main.o $(COVPRGDIR)/covsave.o
COVPRGOBJS += $(filter-out $(OBJTARGETDIR)/main.o,$(OBJECTS))
COVD81 := $(BINTARGETDIR)/icodetestcov.d81
COVLIST := $(BINTARGETDIR)/coverage.txt
# The map and the coverage file of each set
COVARGS = $(foreach s,$(COVSETS),-m $(OBJTARGETDIR)/cov$(s)/icode.map \
	$(BINTARGETDIR)/icode$(s).cov)

# Every file of the overlay is copied, then the set's files are replaced by
# instrumented copies.
$(COVDIR)/stamp: $(ICODESOURCES) $(COVTOOLS)/mkcov.py
	mkdir -p $(COVDIR)
	cp $(ICODESOURCES) $(COVDIR)
	python3 $(COVTOOLS)/mkcov.py -D __MEGA65__ -m $(COVSIZE) \
	$(COVDIR) $(COVDIR)/icode.map \
	$(addprefix $(ICODESRCDIR)/,$(COVFILES$(COVSET)))
	touch $@

$(COVDIR)/%.o: $(COVDIR)/stamp
	ca65 $(COVASFLAGS) -o $@ $(@:.o=.s)

$(COVICODE): $(COVICODEOBJS)
	ld65 -o $@ -C cov/icodecov.cfg $(COVICODEOBJS)

$(COVPRGDIR)/main.o: $(SRCDIR)/main.s $(FLAGSFILE)
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVERAGE -o $@ $<

$(COVPRGDIR)/covsave.o: cov/covsave.s
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVMAP=$(COVMAP) -D COVSIZE=$(COVSIZE) -o $@ $<

$(COVPRG): $(COVPRGOBJS)
	ld65 -o $@ -C icodetest.cfg $(COVPRGOBJS)

# Runs the tests against one set. The test saves the map to the disk.
covrun: $(COVICODE) $(COVPRG) $(BINFILES) $(TXTFILES) | $(BINTARGETDIR)
	$(RM) $(COVD81)
	$(call MKDISK,$(COVD81),$(COVPRG),$(COVICODE))
	../testcommon/runtest.sh icodetestcov$(COVSET) $(COVPRG) $(COVD81)
	c1541 -attach $(COVD81) 	-read icode.cov $(BINTARGETDIR)/icode$(COVSET).cov

# The copies are made fresh each time: they don't track the includes.
coverage:
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(BINTARGETDIR)/icode*.cov
	for s in $(COVSETS); do \
	$(MAKE) TARGET=$(TARGET) DEBUG=1 COVSET=$$s covrun || exit 1; \
	done
	python3 $(COVTOOLS)/covreport.py $(COVLIST) $(COVARGS)

.PHONY: covrun coverage

clean:
	$(RM) $(TXTFILES)
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) $(D81FILE)
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(COVD81) $(COVLIST) $(BINTARGETDIR)/icode*.cov

test:
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

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m icodetest.d81 -r $(BINTARGETDIR)/icodetest

-include $(DEPENDS)
