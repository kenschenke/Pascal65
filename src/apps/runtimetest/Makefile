# runtimetest: tests of the runtime library (src/lib/runtime).
#
# The tests are split into suites. Each suite is its own PRG, built from
# the harness in src/common, its own sources in src/<suite> and the
# runtime files it tests, assembled from the runtime's sources as the
# runtime's Makefile assembles them. A suite that passes loads the next
# (src/common/start.s), so the suites never have to fit in one program.
# make test runs the first; the last prints the result.
#
# To add a suite: add its name to SUITES (in the order they run), put its
# sources in src/<suite>, with a suiteMain that returns when its tests
# pass, and list the runtime files it links in <suite>_RT. Files to
# instrument for make coverage go in <suite>_COV.
#
# make test BUGS=1 adds the tests of known bugs (KNOWN_BUGS), which fail.
# make test TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m" runs only those tests
# of a suite that numbers its tests (heap).

BINDIR := bin
OBJDIR := obj
SRCDIR := src

PROGRAM := runtimetest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

RTSRC := ../../lib/runtime/src
LIBCOMMON := ../../lib/common

# The suites, in the order they run
SUITES := heap

# The runtime heap (memheap.s) and the routines it calls
heap_RT := $(RTSRC)/memheap.s $(LIBCOMMON)/int16comp.s
heap_COV := $(RTSRC)/memheap.s

BUGS ?= 0
TESTSEL ?=
ASFLAGS = -I ../../asminc -I $(SRCDIR)/common $(addprefix -I $(SRCDIR)/,$(SUITES)) \
	-t c64 --cpu 4510 -D __MEGA65__
ifeq ($(BUGS),1)
ASFLAGS += -D KNOWN_BUGS
endif
ifneq ($(TESTSEL),)
ASFLAGS += $(TESTSEL)
endif
# The runtime's own flags (src/lib/runtime/Makefile)
RTASFLAGS = -I ../../asminc -t c64 -D RUNTIME -D __MEGA65__

COMMONSRC := $(wildcard $(SRCDIR)/common/*.s)
COMMONOBJS := $(patsubst $(SRCDIR)/%.s,$(OBJTARGETDIR)/%.o,$(COMMONSRC))
COMMONOBJS += $(OBJTARGETDIR)/testresult.o

# The objects of suite $(1): the harness, its own, its name and the next
# suite's (suiteinfo), and the runtime files it tests
suiteobjs = $(COMMONOBJS) \
	$(patsubst $(SRCDIR)/%.s,$(OBJTARGETDIR)/%.o,$(wildcard $(SRCDIR)/$(1)/*.s)) \
	$(OBJTARGETDIR)/$(1)/suiteinfo.o \
	$(addprefix $(OBJTARGETDIR)/rt/,$(notdir $($(1)_RT:.s=.o)))

PRGFILES := $(addprefix $(BINTARGETDIR)/,$(SUITES))

# The coverage build. make coverage runs each suite with a <suite>_COV list
# against instrumented copies of those files (editortest's cov/mkcov.py)
# on its own, saves the coverage map to its disk and lists the lines that
# never ran in bin/$(TARGET)/coverage-<suite>.txt. The map is COVSIZE bytes
# at COVMAP, above TESTMEM. Like test, it needs a debug build.
MKCOV := ../editortest/cov/mkcov.py
COVREPORT := ../editortest/cov/covreport.py
COVMAP := 36864
COVSIZE := 512
COVSUITES := $(foreach s,$(SUITES),$(if $($(s)_COV),$(s)))
COVDIR := $(OBJTARGETDIR)/cov
COVFLAGS := -D COVMAP=$(COVMAP) -D COVSIZE=$(COVSIZE)

DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILES) $(D81FILE)

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

include ../debug.mk

# The BUGS and TESTSEL settings the objects were built with. Changing them
# rebuilds them.
OPTSFILE = $(OBJTARGETDIR)/opts

$(OPTSFILE): FORCE | $(OBJTARGETDIR)
	@echo "$(BUGS) $(TESTSEL)" | cmp -s - $@ || echo "$(BUGS) $(TESTSEL)" > $@

$(OBJTARGETDIR)/%.o: $(SRCDIR)/%.s $(FLAGSFILE) $(OPTSFILE)
	@mkdir -p $(dir $@)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(OBJTARGETDIR)/testresult.o: ../testcommon/testresult.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

# The runtime's files, as the runtime's Makefile assembles them
$(OBJTARGETDIR)/rt/%.o: $(RTSRC)/%.s
	@mkdir -p $(dir $@)
	ca65 $(RTASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(OBJTARGETDIR)/rt/%.o: $(LIBCOMMON)/%.s
	@mkdir -p $(dir $@)
	ca65 $(RTASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

# A suite's name, the next suite's (empty for the last) and the name of
# its coverage map. $(1) is the file, $(2) the suite, $(3) the next.
define writeinfo
	@mkdir -p $(dir $(1))
	printf '.export suiteName, nextSuite, covName\n.rodata\nsuiteName: .asciiz "%s"\nnextSuite: .asciiz "%s"\ncovName: .asciiz "%s.cov"\n' '$(2)' '$(3)' '$(2)' > $(1)
endef

# The rules for suite $(1), which $(2) follows
define SUITE_RULES
$(OBJTARGETDIR)/$(1)/suiteinfo.s: Makefile
	$$(call writeinfo,$$@,$(1),$(2))

$(OBJTARGETDIR)/$(1)/suiteinfo.o: $(OBJTARGETDIR)/$(1)/suiteinfo.s
	ca65 $$(ASFLAGS) -o $$@ $$<

$(BINTARGETDIR)/$(1): $(call suiteobjs,$(1)) runtimetest.cfg | $(BINTARGETDIR)
	ld65 -o $$@ -C runtimetest.cfg -m $(OBJTARGETDIR)/$(1).map $(call suiteobjs,$(1))

# The coverage build of the suite: the instrumented copies replace the
# runtime files they were made from, and it runs alone
COVOBJS_$(1) := $(filter-out $(OBJTARGETDIR)/common/start.o \
	$(addprefix $(OBJTARGETDIR)/rt/,$(notdir $($(1)_COV:.s=.o))) \
	$(OBJTARGETDIR)/$(1)/suiteinfo.o,$(call suiteobjs,$(1))) \
	$(COVDIR)/$(1)/start.o $(COVDIR)/$(1)/suiteinfo.o \
	$(addprefix $(COVDIR)/$(1)/,$(notdir $($(1)_COV:.s=.o)))

# The copies' long branches need --cpu 4510, where sp is a register, so
# they get a runtime.inc that calls the runtime's sp rtsp
$(COVDIR)/$(1)/stamp: $($(1)_COV) $(MKCOV) ../../asminc/runtime.inc
	mkdir -p $(COVDIR)/$(1)/inc
	python3 $(MKCOV) -m $(COVSIZE) $(COVDIR)/$(1) $(COVDIR)/$(1)/$(1).map $($(1)_COV)
	sed -e 's/^sp :=/rtsp :=/' ../../asminc/runtime.inc > $(COVDIR)/$(1)/inc/runtime.inc
	touch $$@

$(addprefix $(COVDIR)/$(1)/,$(notdir $($(1)_COV:.s=.o))): $(COVDIR)/$(1)/stamp
	ca65 -I $(COVDIR)/$(1)/inc $(RTASFLAGS) --cpu 4510 $(COVFLAGS) -o $$@ $$(@:.o=.s)

$(COVDIR)/$(1)/start.o: $(SRCDIR)/common/start.s $(FLAGSFILE)
	@mkdir -p $(COVDIR)/$(1)
	ca65 $$(ASFLAGS) -D COVERAGE $(COVFLAGS) -o $$@ $$<

$(COVDIR)/$(1)/suiteinfo.s: Makefile
	$$(call writeinfo,$$@,$(1),)

$(COVDIR)/$(1)/suiteinfo.o: $(COVDIR)/$(1)/suiteinfo.s
	ca65 $$(ASFLAGS) -o $$@ $$<

$(BINTARGETDIR)/$(1)cov: $$(COVOBJS_$(1)) runtimetest.cfg | $(BINTARGETDIR)
	ld65 -o $$@ -C runtimetest.cfg $$(COVOBJS_$(1))

# The disk is made fresh for each run because the suite saves the map to it
covrun-$(1): $(BINTARGETDIR)/$(1)cov
	$(RM) $(BINTARGETDIR)/$(1)cov.d81 $(BINTARGETDIR)/$(1).cov
	c1541 -format $(1)cov,8a d81 $(BINTARGETDIR)/$(1)cov.d81 \
	-write $(BINTARGETDIR)/$(1)cov $(1),prg
	../testcommon/runtest.sh $(1)cov $(BINTARGETDIR)/$(1)cov \
	$(BINTARGETDIR)/$(1)cov.d81
	c1541 -attach $(BINTARGETDIR)/$(1)cov.d81 -read $(1).cov \
	$(BINTARGETDIR)/$(1).cov
	python3 $(COVREPORT) $(BINTARGETDIR)/coverage-$(1).txt \
	-m $(COVDIR)/$(1)/$(1).map $(BINTARGETDIR)/$(1).cov
endef

nextsuite = $(strip $(word $(shell expr $(1) + 1),$(SUITES)))
$(foreach i,$(shell seq 1 $(words $(SUITES))), \
	$(eval $(call SUITE_RULES,$(word $(i),$(SUITES)),$(call nextsuite,$(i)))))

$(D81FILE): $(PRGFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	$(foreach s,$(SUITES),-write $(BINTARGETDIR)/$(s) $(s),prg)

clean:
	$(RM) -r $(OBJTARGETDIR)
	$(RM) $(D81FILE) $(PRGFILES)
	$(RM) $(addprefix $(BINTARGETDIR)/,$(addsuffix cov,$(SUITES)))
	$(RM) $(addprefix $(BINTARGETDIR)/,$(addsuffix cov.d81,$(SUITES)))
	$(RM) $(addprefix $(BINTARGETDIR)/,$(addsuffix .cov,$(SUITES)))
	$(RM) $(addprefix $(BINTARGETDIR)/coverage-,$(addsuffix .txt,$(SUITES)))

test:
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(BINTARGETDIR)/$(firstword $(SUITES)) \
	$(D81FILE)

# Like test, coverage runs a debug build. The copies are made fresh each
# time: they don't track the includes.
coverage:
	$(RM) -r $(COVDIR)
	$(MAKE) TARGET=$(TARGET) DEBUG=1 $(addprefix covrun-,$(COVSUITES))

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

.PHONY: all clean test coverage run FORCE $(addprefix covrun-,$(SUITES))

-include $(shell find $(OBJTARGETDIR) -name '*.d' 2>/dev/null)
