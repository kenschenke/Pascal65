BINDIR := bin
OBJDIR := obj
SRCDIR := src
TESTSDIR := tests
ERRORTESTSDIR := errortests
PETSCIIDIR := petscii
TOKENIZERDIR := ../../overlays/tokenizerasm
PARSERDIR := ../../overlays/parserasm
DUMPASTDIR := ../../overlays/dumpast
MEMINFODIR := ../../overlays/meminfo
SHOWTREEDIR := ../../overlays/showtree
ASMLIBDIR := ../../lib/asmlib

PROGRAM := parsertest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -I $(OBJTARGETDIR) -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
DUMPAST = ../../overlays/dumpast/bin/$(TARGET)/dumpast
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
SHOWTREE = ../../overlays/showtree/bin/$(TARGET)/showtree
PRGFILE = $(BINTARGETDIR)/parsertest

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(DUMPAST)
BINFILES += $(ASMLIB)
BINFILES += $(MEMINFO)
BINFILES += $(SHOWTREE)
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

TXTFILES := errormsgs.petscii

TESTS := $(wildcard $(TESTSDIR)/*.pas)
ERRORTESTS := $(wildcard $(ERRORTESTSDIR)/*.pas)
TXTFILES += $(patsubst $(TESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(TESTS))
TXTFILES += $(patsubst $(ERRORTESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(ERRORTESTS))
comma := ,

# The expected error of each error test, from the header comments of the
# tests (see mkerrortests.py)
ERRORTABLE := $(OBJTARGETDIR)/errortests.inc

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

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

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(DUMPAST): FORCE
	cd $(DUMPASTDIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(SHOWTREE): FORCE
	cd $(SHOWTREEDIR) && $(MAKE) TARGET=$(TARGET)

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

# The names of the error tests, so that taking one out remakes the table
ERRORLIST := $(OBJTARGETDIR)/errortests

$(ERRORLIST): FORCE | $(OBJTARGETDIR)
	@echo "$(ERRORTESTS)" | cmp -s - $@ || echo "$(ERRORTESTS)" > $@

$(ERRORTABLE): $(ERRORTESTS) $(ERRORLIST) mkerrortests.py | $(OBJTARGETDIR)
	python3 mkerrortests.py $@ $(ERRORTESTS)

# ERRTESTS="-D FIRST_ERROR_TEST=n -D LAST_ERROR_TEST=m" runs only those
# error tests, to find one that hangs. The setting is kept in a file so a
# change rebuilds runerrortests.o.
ERRTESTS ?=
ERRTESTSFILE := $(OBJTARGETDIR)/errtests

$(ERRTESTSFILE): FORCE | $(OBJTARGETDIR)
	@echo "$(ERRTESTS)" | cmp -s - $@ || echo "$(ERRTESTS)" > $@

$(OBJTARGETDIR)/runerrortests.o: ASFLAGS += $(ERRTESTS)
$(OBJTARGETDIR)/runerrortests.o: $(ERRORTABLE) $(ERRTESTSFILE)

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C parsertest.cfg $(OBJECTS)

FORCE:

# Makes a disk: $(1) is the D81, $(2) the test program and $(3) the parser
define MKDISK
c1541 -format $(PROGRAM),8a d81 $(1) \
	-write $(2) parsertest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(3) parser,prg \
	-write $(DUMPAST) dumpast,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(SHOWTREE) showtree,prg \
	-write $(ASMLIB) asm.lib,prg \
	$(foreach f,$(notdir $(TESTS) $(ERRORTESTS)), \
	-write $(PETSCIIDIR)/$(f) $(f)$(comma)seq) \
	-write errormsgs.petscii errormsgs.txt,seq
endef

$(D81FILE): $(BINFILES) $(TXTFILES)
	$(call MKDISK,$(D81FILE),$(PRGFILE),$(PARSER))

# The coverage build. make coverage runs the tests against instrumented
# copies of the parser overlay (see ../editortest/cov/mkcov.py) and lists
# the lines that never ran in bin/$(TARGET)/coverage.txt. Like test, it
# needs asmlib built with MEMCHECK=1.
#
# The probes make the overlay much bigger, and they don't all fit at once.
# Each set instruments some of the files and the tests run once for each
# set. A set's map is COVSIZE bytes at COVMAP, above the test program. A set
# that no longer fits fails to link and must be split.
COVTOOLS := ../editortest/cov
COVMAP := 15360
COVSIZE := 1024
COVSETS := 1 2 3
COVSET ?= 1
# Module, declarations and the shared routines
COVFILES1 := addUnit.s appendDecl.s getToken.s parseBlock.s parseConstant.s \
	parseConstantDefinitions.s parseDeclarations.s parseIdSublist.s \
	parseModule.s parseModuleHeader.s parser.s parseSubroutine.s \
	parseSubroutineDeclarations.s parseTypeDefinitions.s \
	parseUsesReferences.s parseVariableDeclarations.s resync.s
# Types and routine headers
COVFILES2 := parseArrayLiteral.s parseArrayType.s parseEnumerationType.s \
	parseFileType.s parseFormalParamList.s parseFuncOrProcHeader.s \
	parseRecordType.s parseSubrangeLimit.s parseSubrangeType.s \
	parseTypeSpec.s
# Statements and expressions
COVFILES3 := parseActualParm.s parseActualParmList.s parseAssignment.s \
	parseCase.s parseCaseBranch.s parseCaseLabel.s parseCompound.s \
	parseExpression.s parseFactor.s parseField.s parseFor.s \
	parseIdentifier.s parseIf.s parseRepeat.s parseSimpleExpression.s \
	parseStatement.s parseStatementList.s parseSubroutineCall.s \
	parseSubscripts.s parseTerm.s parseVariable.s parseWhile.s

PARSERSRCDIR := $(PARSERDIR)/src
PARSERSOURCES := $(wildcard $(PARSERSRCDIR)/*.s)
COVASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__ \
	-D COVMAP=$(COVMAP)
COVDIR := $(OBJTARGETDIR)/cov$(COVSET)
COVPARSEROBJS := $(addprefix $(COVDIR)/,$(notdir $(PARSERSOURCES:.s=.o)))
COVPARSER := $(COVDIR)/parser
COVPRGDIR := $(OBJTARGETDIR)/cov
COVPRG := $(COVPRGDIR)/$(PROGRAM)
COVPRGOBJS := $(COVPRGDIR)/main.o $(COVPRGDIR)/covsave.o
COVPRGOBJS += $(filter-out $(OBJTARGETDIR)/main.o,$(OBJECTS))
COVD81 := $(BINTARGETDIR)/parsertestcov.d81
COVLIST := $(BINTARGETDIR)/coverage.txt
# The map and the coverage file of each set
COVARGS = $(foreach s,$(COVSETS),-m $(OBJTARGETDIR)/cov$(s)/parser.map \
	$(BINTARGETDIR)/parser$(s).cov)

# Every file of the overlay is copied, then the set's files are replaced by
# instrumented copies.
$(COVDIR)/stamp: $(PARSERSOURCES) $(COVTOOLS)/mkcov.py
	mkdir -p $(COVDIR)
	cp $(PARSERSOURCES) $(COVDIR)
	python3 $(COVTOOLS)/mkcov.py -D __MEGA65__ -m $(COVSIZE) \
	$(COVDIR) $(COVDIR)/parser.map \
	$(addprefix $(PARSERSRCDIR)/,$(COVFILES$(COVSET)))
	touch $@

$(COVDIR)/%.o: $(COVDIR)/stamp
	ca65 $(COVASFLAGS) -o $@ $(@:.o=.s)

$(COVPARSER): $(COVPARSEROBJS)
	ld65 -o $@ -C cov/parsercov.cfg $(COVPARSEROBJS)

$(COVPRGDIR)/main.o: $(SRCDIR)/main.s $(FLAGSFILE)
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVERAGE -o $@ $<

$(COVPRGDIR)/covsave.o: cov/covsave.s
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVMAP=$(COVMAP) -D COVSIZE=$(COVSIZE) -o $@ $<

$(COVPRG): $(COVPRGOBJS)
	ld65 -o $@ -C parsertest.cfg $(COVPRGOBJS)

# Runs the tests against one set. The test saves the map to the disk.
covrun: $(COVPARSER) $(COVPRG) $(BINFILES) $(TXTFILES) | $(BINTARGETDIR)
	$(RM) $(COVD81)
	$(call MKDISK,$(COVD81),$(COVPRG),$(COVPARSER))
	../testcommon/runtest.sh parsertestcov$(COVSET) $(COVPRG) $(COVD81)
	c1541 -attach $(COVD81) -read parser.cov $(BINTARGETDIR)/parser$(COVSET).cov

# The copies are made fresh each time: they don't track the includes.
coverage:
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(BINTARGETDIR)/parser*.cov
	for s in $(COVSETS); do \
	$(MAKE) TARGET=$(TARGET) DEBUG=1 COVSET=$$s covrun || exit 1; \
	done
	python3 $(COVTOOLS)/covreport.py $(COVLIST) $(COVARGS)

.PHONY: covrun coverage

clean:
	$(RM) $(TXTFILES)
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) $(D81FILE) $(ERRORTABLE)
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(COVD81) $(COVLIST) $(BINTARGETDIR)/parser*.cov

test:
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE)

.PHONY: test

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m parsertest.d81 -r $(BINTARGETDIR)/parsertest

-include $(DEPENDS)
