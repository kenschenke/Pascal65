BINDIR := bin
OBJDIR := obj
SRCDIR := src
TESTSDIR := tests
ERRORTESTSDIR := errortests
PETSCIIDIR := petscii
TOKENIZERDIR := ../../overlays/tokenizerasm
PARSERDIR := ../../overlays/parserasm
SHOWTREEDIR := ../../overlays/showtree
DUMPASTDIR := ../../overlays/dumpast
RESOLVERDIR := ../../overlays/resolverasm
TYPECHECKDIR := ../../overlays/typecheckasm
MEMINFODIR := ../../overlays/meminfo
ASMLIBDIR := ../../lib/asmlib

PROGRAM := typechecktest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
SHOWTREE = ../../overlays/showtree/bin/$(TARGET)/showtree
DUMPAST = ../../overlays/dumpast/bin/$(TARGET)/dumpast
RESOLVER = ../../overlays/resolverasm/bin/$(TARGET)/resolver
TYPECHECK = ../../overlays/typecheckasm/bin/$(TARGET)/typecheck
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
PRGFILE = $(BINTARGETDIR)/typechecktest
SYSTEMPAS = ../../lib/system/system.pas

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(SHOWTREE)
BINFILES += $(DUMPAST)
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

$(PARSER): FORCE
	cd $(PARSERDIR) && $(MAKE) TARGET=$(TARGET)

$(RESOLVER): FORCE
	cd $(RESOLVERDIR) && $(MAKE) TARGET=$(TARGET)

$(TYPECHECK): FORCE
	cd $(TYPECHECKDIR) && $(MAKE) TARGET=$(TARGET)

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(SHOWTREE): FORCE
	cd $(SHOWTREEDIR) && $(MAKE) TARGET=$(TARGET)

$(DUMPAST): FORCE
	cd $(DUMPASTDIR) && $(MAKE) TARGET=$(TARGET)

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

# TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m" runs only those program tests,
# and -D FIRST_ERROR_TEST and -D LAST_ERROR_TEST only those error tests.
# A first test after the last runs none. The setting is kept in a file so
# a change rebuilds the objects.
TESTSEL ?=
TESTSFILE := $(OBJTARGETDIR)/testsel

$(TESTSFILE): FORCE | $(OBJTARGETDIR)
	@echo "$(TESTSEL)" | cmp -s - $@ || echo "$(TESTSEL)" > $@

$(OBJTARGETDIR)/runtests.o $(OBJTARGETDIR)/runerrortests.o: ASFLAGS += $(TESTSEL)
$(OBJTARGETDIR)/runtests.o $(OBJTARGETDIR)/runerrortests.o: $(TESTSFILE)

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C typechecktest.cfg $(OBJECTS)

FORCE:

# Makes a disk: $(1) is the D81, $(2) the test program and $(3) the
# typecheck overlay. Every .pas file in tests goes on it.
define MKDISK
c1541 -format $(PROGRAM),8a d81 $(1) \
	-write $(2) typechecktest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(PARSER) parser,prg \
	-write $(RESOLVER) resolver,prg \
	-write $(3) typecheck,prg \
	-write $(DUMPAST) dumpast,prg \
	-write $(SHOWTREE) showtree,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(ASMLIB) asm.lib,prg \
	$(foreach f,$(notdir $(TESTS) $(ERRORTESTS)), \
	-write $(PETSCIIDIR)/$(f) $(f)$(comma)seq) \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write system.petscii system.pas,seq
endef

$(D81FILE): $(BINFILES) $(TXTFILES)
	$(call MKDISK,$(D81FILE),$(PRGFILE),$(TYPECHECK))

# The coverage build. make coverage runs the tests against instrumented
# copies of the typecheck overlay (see ../editortest/cov/mkcov.py) and lists
# the lines that never ran in bin/$(TARGET)/coverage.txt. Like test, it
# needs asmlib built with MEMCHECK=1.
#
# The probes make the overlay much bigger, and they don't all fit at once.
# Each set instruments some of the files and the tests run once for each
# set. A set's map is COVSIZE bytes at COVMAP, above the test program. A set
# that no longer fits fails to link and must be split. exprTypeCheck.s is
# too big for one set, so two sets each instrument part of it, split at
# a proc (mkcov.py's <in.s>:<first>-<last>).
COVTOOLS := ../editortest/cov
COVMAP := 14848
COVSIZE := 1536
COVSETS := 1 2 3 4 5 6 7 8
COVSET ?= 1
# Expressions and declarations
COVFILES1 := exprTypeCheck.s:-evalNegate declTypeCheck.s typecheck.s \
	typeCheckUnits.s
COVFILES2 := exprTypeCheck.s:evalNegate- declTypeCheckType.s \
	isExprAFuncCall.s isExprARoutineCall.s isExprATypeDeclaration.s \
	isAssignableToString.s getTypeSize.s getTypeConversion.s hoistFuncCall.s
# Routine calls
COVFILES3 := checkFuncProcCall.s checkStdParms.s checkArray.s \
	checkIntegerBaseType.s realOperands.s integerOperands.s
# Standard routines
COVFILES4 := checkWriteWritelnCall.s checkReadReadlnCall.s \
	checkReadStrCall.s checkStdRoutine.s
# Operators and assignments
COVFILES5 := checkRelOpOperands.s getBinaryExpressionType.s \
	checkAssignment.s
# Statements, compatibility and forwards
COVFILES6 := stmtTypeCheck.s isAssignmentCompatible.s \
	checkForwardVsFormalDeclaration.s checkArrayRoutineCall.s
# Literals, arrays and the other standard routines
COVFILES7 := exprLiteral.s checkArrayLiteral.s getArrayType.s \
	checkDecIncCall.s checkPredSuccCall.s checkArraysSameType.s \
	declTypeCheckValue.s evalArrayLiteral.s checkAbsSqrCall.s
# Case, casts and the small helpers
COVFILES8 := caseTypeCheck.s checkTypeCast.s checkBoolOperand.s \
	isTypeNumeric.s isTypeOrdinal.s isTypeInteger.s

TYPECHECKSRCDIR := $(TYPECHECKDIR)/src
TYPECHECKSOURCES := $(wildcard $(TYPECHECKSRCDIR)/*.s)
COVASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__ \
	-D COVMAP=$(COVMAP)
COVDIR := $(OBJTARGETDIR)/cov$(COVSET)
COVTYPECHECKOBJS := $(addprefix $(COVDIR)/, \
	$(notdir $(TYPECHECKSOURCES:.s=.o)))
COVTYPECHECK := $(COVDIR)/typecheck
COVPRGDIR := $(OBJTARGETDIR)/cov
COVPRG := $(COVPRGDIR)/$(PROGRAM)
COVPRGOBJS := $(COVPRGDIR)/main.o $(COVPRGDIR)/covsave.o
COVPRGOBJS += $(filter-out $(OBJTARGETDIR)/main.o,$(OBJECTS))
COVD81 := $(BINTARGETDIR)/typechecktestcov.d81
COVLIST := $(BINTARGETDIR)/coverage.txt
# The map and the coverage file of each set
COVARGS = $(foreach s,$(COVSETS),-m $(OBJTARGETDIR)/cov$(s)/typecheck.map \
	$(BINTARGETDIR)/typecheck$(s).cov)

# Every file of the overlay is copied, then the set's files are replaced by
# instrumented copies.
$(COVDIR)/stamp: $(TYPECHECKSOURCES) $(COVTOOLS)/mkcov.py
	mkdir -p $(COVDIR)
	cp $(TYPECHECKSOURCES) $(COVDIR)
	python3 $(COVTOOLS)/mkcov.py -D __MEGA65__ -m $(COVSIZE) \
	$(COVDIR) $(COVDIR)/typecheck.map \
	$(addprefix $(TYPECHECKSRCDIR)/,$(COVFILES$(COVSET)))
	touch $@

$(COVDIR)/%.o: $(COVDIR)/stamp
	ca65 $(COVASFLAGS) -o $@ $(@:.o=.s)

$(COVTYPECHECK): $(COVTYPECHECKOBJS)
	ld65 -o $@ -C cov/typecheckcov.cfg $(COVTYPECHECKOBJS)

$(COVPRGDIR)/main.o: $(SRCDIR)/main.s $(FLAGSFILE)
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVERAGE -o $@ $<

$(COVPRGDIR)/covsave.o: cov/covsave.s
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVMAP=$(COVMAP) -D COVSIZE=$(COVSIZE) -o $@ $<

$(COVPRG): $(COVPRGOBJS)
	ld65 -o $@ -C typechecktest.cfg $(COVPRGOBJS)

# Runs the tests against one set. The test saves the map to the disk.
covrun: $(COVTYPECHECK) $(COVPRG) $(BINFILES) $(TXTFILES) | $(BINTARGETDIR)
	$(RM) $(COVD81)
	$(call MKDISK,$(COVD81),$(COVPRG),$(COVTYPECHECK))
	../testcommon/runtest.sh typechecktestcov$(COVSET) $(COVPRG) $(COVD81)
	c1541 -attach $(COVD81) \
	-read typecheck.cov $(BINTARGETDIR)/typecheck$(COVSET).cov

# The copies are made fresh each time: they don't track the includes.
coverage:
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(BINTARGETDIR)/typecheck*.cov
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
	$(RM) $(COVD81) $(COVLIST) $(BINTARGETDIR)/typecheck*.cov

test:
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE)

.PHONY: test

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m typechecktest.d81 -r $(BINTARGETDIR)/typechecktest

-include $(DEPENDS)
