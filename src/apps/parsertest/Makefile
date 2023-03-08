SRCDIR := src
OBJDIR := obj
BINDIR := bin
DRVDIR := ../../../drv
TOKENIZEROVRLSRC := ../../overlays/tokenizer
PARSEROVRLSRC := ../../overlays/parser
TESTOVRLSRC := ../../overlays/parsertest
SHAREDSRCDIR = ../../shared
SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks
SHAREDICODEDIR = $(SHAREDSRCDIR)/icode
SHAREDMEMBUFDIR = $(SHAREDSRCDIR)/membuf
LIBCSRCDIR = ../../mega65-libc/src
LIBCOMMONDIR = ../../lib/common
TARGETSRCDIR = $(SRCDIR)/$(TARGET)
TESTSDIR = tests

PROGRAM := parsertest
D81FILE := $(BINDIR)/$(PROGRAM).d81
TOKENIZEROVRLFILE := $(PROGRAM).1
PARSEROVRLFILE := $(PROGRAM).2
TESTOVRLFILE := $(PROGRAM).3
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := c64
CC65TARGET = c64
c64_EMUCMD = x64sc -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
c128_EMUCMD = x128 -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)
DRVFILE = $(DRVDIR)/$(TARGET)-reu.emd

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -D __TEST__ -I ../../mega65-libc/include
CONFIG := cfg-$(TARGET).cfg
CFLAGS = $($(TARGET)_CFLAGS) -W error -D MAINPAS -D __TEST__ -O -I ../../include
ASFLAGS = --asm-include-dir ../../asminc
LDFLAGS = --mapfile parsertest.map -C $(CONFIG)

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.c)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.c)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.s)
SOURCES += $(wildcard $(SHAREDICODEDIR)/*.c)
SOURCES += $(wildcard $(SHAREDICODEDIR)/*.s)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.c)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.s)
SOURCES += $(wildcard $(LIBCOMMONDIR)/*.c)
SOURCES += $(wildcard $(LIBCOMMONDIR)/*.s)
ifeq ($(TARGET),mega65)
SOURCES += $(LIBCSRCDIR)/memory.c
endif

TOKENIZEROVRLSRCS := $(wildcard $(TOKENIZEROVRLSRC)/*.c)

PARSEROVRLSRCS := $(wildcard $(PARSEROVRLSRC)/*.c)
PARSEROVRLSRCS += $(wildcard $(PARSEROVRLSRC)/*.s)

TESTOVRLSRCS := $(wildcard $(TESTOVRLSRC)/*.c)
TESTOVRLSRCS += $(wildcard $(TESTOVRLSRC)/*.s)

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(TOKENIZEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(PARSEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(TESTOVRLSRCS)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(D81FILE)

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

vpath %.c $(SRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(TARGETSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(TARGETSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(TOKENIZEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(TOKENIZEROVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(TESTOVRLSRC)/%.c
$(OBJDIR)/%.o: $(TESTOVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(TESTOVRLSRC)/%.s
$(OBJDIR)/%.o: $(TESTOVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.c
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.s
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.c
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.s
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCHUNKSDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCHUNKSDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDICODEDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDICODEDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDMEMBUFDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDMEMBUFDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

abortmsgs.petscii: $(SHAREDSRCDIR)/abortmsgs.txt
	dos2unix < $(SHAREDSRCDIR)/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

errormsgs.petscii: $(SHAREDSRCDIR)/errormsgs.txt
	dos2unix < $(SHAREDSRCDIR)/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

runtimemsgs.petscii: $(SHAREDSRCDIR)/runtimemsgs.txt
	dos2unix < $(SHAREDSRCDIR)/runtimemsgs.txt | petcat -w2 -text -o runtimemsgs.petscii

routines.petscii: routines.pas
	dos2unix < routines.pas | petcat -w2 -text -o routines.petscii

translate.petscii: translate.pas
	dos2unix < translate.pas | petcat -w2 -text -o translate.petscii

arraytest.petscii: $(TESTSDIR)/arraytest.pas
	dos2unix < $(TESTSDIR)/arraytest.pas | petcat -w2 -text -o arraytest.petscii

arraytext.petscii: $(TESTSDIR)/arraytest.txt
	dos2unix < $(TESTSDIR)/arraytest.txt | petcat -w2 -text -o arraytext.petscii

casechartest.petscii: $(TESTSDIR)/casechartest.pas
	dos2unix < $(TESTSDIR)/casechartest.pas | petcat -w2 -text -o casechartest.petscii

casechartext.petscii: $(TESTSDIR)/casechartest.txt
	dos2unix < $(TESTSDIR)/casechartest.txt | petcat -w2 -text -o casechartext.petscii

caseenumtest.petscii: $(TESTSDIR)/caseenumtest.pas
	dos2unix < $(TESTSDIR)/caseenumtest.pas | petcat -w2 -text -o caseenumtest.petscii

caseenumtext.petscii: $(TESTSDIR)/caseenumtest.txt
	dos2unix < $(TESTSDIR)/caseenumtest.txt | petcat -w2 -text -o caseenumtext.petscii

caseinttest.petscii: $(TESTSDIR)/caseinttest.pas
	dos2unix < $(TESTSDIR)/caseinttest.pas | petcat -w2 -text -o caseinttest.petscii

caseinttext.petscii: $(TESTSDIR)/caseinttest.txt
	dos2unix < $(TESTSDIR)/caseinttest.txt | petcat -w2 -text -o caseinttext.petscii

consttest.petscii: $(TESTSDIR)/consttest.pas
	dos2unix < $(TESTSDIR)/consttest.pas | petcat -w2 -text -o consttest.petscii

consttext.petscii: $(TESTSDIR)/consttest.txt
	dos2unix < $(TESTSDIR)/consttest.txt | petcat -w2 -text -o consttext.petscii

enumtest.petscii: $(TESTSDIR)/enumtest.pas
	dos2unix < $(TESTSDIR)/enumtest.pas | petcat -w2 -text -o enumtest.petscii

enumtext.petscii: $(TESTSDIR)/enumtest.txt
	dos2unix < $(TESTSDIR)/enumtest.txt | petcat -w2 -text -o enumtext.petscii

fortest.petscii: $(TESTSDIR)/fortest.pas
	dos2unix < $(TESTSDIR)/fortest.pas | petcat -w2 -text -o fortest.petscii

fortext.petscii: $(TESTSDIR)/fortest.txt
	dos2unix < $(TESTSDIR)/fortest.txt | petcat -w2 -text -o fortext.petscii

iftest.petscii: $(TESTSDIR)/iftest.pas
	dos2unix < $(TESTSDIR)/iftest.pas | petcat -w2 -text -o iftest.petscii

iftext.petscii: $(TESTSDIR)/iftest.txt
	dos2unix < $(TESTSDIR)/iftest.txt | petcat -w2 -text -o iftext.petscii

recordtest.petscii: $(TESTSDIR)/recordtest.pas
	dos2unix < $(TESTSDIR)/recordtest.pas | petcat -w2 -text -o recordtest.petscii

recordtext.petscii: $(TESTSDIR)/recordtest.txt
	dos2unix < $(TESTSDIR)/recordtest.txt | petcat -w2 -text -o recordtext.petscii

repeattest.petscii: $(TESTSDIR)/repeattest.pas
	dos2unix < $(TESTSDIR)/repeattest.pas | petcat -w2 -text -o repeattest.petscii

repeattext.petscii: $(TESTSDIR)/repeattest.txt
	dos2unix < $(TESTSDIR)/repeattest.txt | petcat -w2 -text -o repeattext.petscii

routinetest.petscii: $(TESTSDIR)/routinetest.pas
	dos2unix < $(TESTSDIR)/routinetest.pas | petcat -w2 -text -o routinetest.petscii

scalartest.petscii: $(TESTSDIR)/scalartest.pas
	dos2unix < $(TESTSDIR)/scalartest.pas | petcat -w2 -text -o scalartest.petscii

scalartext.petscii: $(TESTSDIR)/scalartest.txt
	dos2unix < $(TESTSDIR)/scalartest.txt | petcat -w2 -text -o scalartext.petscii

stdrtntest.petscii: $(TESTSDIR)/stdrtntest.pas
	dos2unix < $(TESTSDIR)/stdrtntest.pas | petcat -w2 -text -o stdrtntest.petscii

stdrtntext.petscii: $(TESTSDIR)/stdrtntest.txt
	dos2unix < $(TESTSDIR)/stdrtntest.txt | petcat -w2 -text -o stdrtntext.petscii

subrangetest.petscii: $(TESTSDIR)/subrangetest.pas
	dos2unix < $(TESTSDIR)/subrangetest.pas | petcat -w2 -text -o subrangetest.petscii

vartest.petscii: $(TESTSDIR)/vartest.pas
	dos2unix < $(TESTSDIR)/vartest.pas | petcat -w2 -text -o vartest.petscii

whiletest.petscii: $(TESTSDIR)/whiletest.pas
	dos2unix < $(TESTSDIR)/whiletest.pas | petcat -w2 -text -o whiletest.petscii

whiletext.petscii: $(TESTSDIR)/whiletest.txt
	dos2unix < $(TESTSDIR)/whiletest.txt | petcat -w2 -text -o whiletext.petscii

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) $(OBJECTS)

ifeq ($(TARGET),mega65)
$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(TOKENIZEROVRLFILE) $(TOKENIZEROVRLFILE) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(TESTOVRLFILE) $(TESTOVRLFILE) \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq
else
$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii arraytest.petscii arraytext.petscii casechartest.petscii casechartext.petscii caseenumtest.petscii caseenumtext.petscii caseinttest.petscii caseinttext.petscii consttest.petscii consttext.petscii enumtest.petscii enumtext.petscii fortest.petscii fortext.petscii iftest.petscii iftext.petscii recordtest.petscii recordtext.petscii repeattest.petscii repeattext.petscii routinetest.petscii scalartest.petscii scalartext.petscii stdrtntest.petscii stdrtntext.petscii subrangetest.petscii vartest.petscii whiletest.petscii whiletext.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(TOKENIZEROVRLFILE) $(TOKENIZEROVRLFILE) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(TESTOVRLFILE) $(TESTOVRLFILE) \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write arraytest.petscii arraytest.pas,seq \
	-write arraytext.petscii arraytest.txt,seq \
	-write casechartest.petscii casechartest.pas,seq \
	-write casechartext.petscii casechartest.txt,seq \
	-write caseenumtest.petscii caseenumtest.pas,seq \
	-write caseenumtext.petscii caseenumtest.txt,seq \
	-write caseinttest.petscii caseinttest.pas,seq \
	-write caseinttext.petscii caseinttest.txt,seq \
	-write consttest.petscii consttest.pas,seq \
	-write consttext.petscii consttest.txt,seq \
	-write enumtest.petscii enumtest.pas,seq \
	-write enumtext.petscii enumtest.txt,seq \
	-write fortest.petscii fortest.pas,seq \
	-write fortext.petscii fortest.txt,seq \
	-write iftest.petscii iftest.pas,seq \
	-write iftext.petscii iftest.txt,seq \
	-write recordtest.petscii recordtest.pas,seq \
	-write recordtext.petscii recordtest.txt,seq \
	-write repeattest.petscii repeattest.pas,seq \
	-write repeattext.petscii repeattest.txt,seq \
	-write routinetest.petscii routinetest.pas,seq \
	-write scalartest.petscii scalartest.pas,seq \
	-write scalartext.petscii scalartest.txt,seq \
	-write stdrtntest.petscii stdrtntest.pas,seq \
	-write stdrtntext.petscii stdrtntest.txt,seq \
	-write subrangetest.petscii subrangetest.pas,seq \
	-write vartest.petscii vartest.pas,seq \
	-write whiletest.petscii whiletest.pas,seq \
	-write whiletext.petscii whiletest.txt,seq \
	-write $(DRVFILE) $(TARGET)-reu.emd,prg
endif

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
