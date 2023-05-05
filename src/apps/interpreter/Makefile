SRCDIR := src
OBJDIR := obj
BINDIR := bin
DRVDIR := ../../../drv
TOKENIZEROVRLSRC := ../../overlays/tokenizer
PARSEROVRLSRC := ../../overlays/parser
EXECOVRLSRC := ../../overlays/exec
SHAREDSRCDIR = ../../shared
SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks
SHAREDICODEDIR = $(SHAREDSRCDIR)/icode
SHAREDMEMBUFDIR = $(SHAREDSRCDIR)/membuf
LIBCSRCDIR = ../../mega65-libc/src
LIBCOMMONDIR = ../../lib/common
TARGETSRCDIR = $(SRCDIR)/$(TARGET)

PROGRAM := interpreter
D81FILE := $(BINDIR)/$(PROGRAM).d81
TOKENIZEROVRLFILE := $(PROGRAM).1
PARSEROVRLFILE := $(PROGRAM).2
EXECOVRLFILE := $(PROGRAM).3
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64
c64_EMUCMD = x64sc -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
c128_EMUCMD = x128 -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)
DRVFILE = $(DRVDIR)/$(TARGET)-reu.emd

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
CONFIG := cfg-$(TARGET).cfg
CFLAGS = $($(TARGET)_CFLAGS) -W error -D MAINPAS -O -I ../../include
ASFLAGS = --asm-include-dir ../../asminc
LDFLAGS = --mapfile interpreter.map -C $(CONFIG)

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
SOURCES += $(LIBCOMMONDIR)/int16.s
SOURCES += $(LIBCOMMONDIR)/floatcomp.s
SOURCES += $(LIBCOMMONDIR)/uint16comp.s
SOURCES += $(LIBCOMMONDIR)/int16comp.s
ifeq ($(TARGET),mega65)
SOURCES += $(LIBCSRCDIR)/memory.c
endif

TOKENIZEROVRLSRCS := $(wildcard $(TOKENIZEROVRLSRC)/*.c)
TOKENIZEROVRLSRCS += $(wildcard $(TOKENIZEROVRLSRC)/*.s)

PARSEROVRLSRCS := $(wildcard $(PARSEROVRLSRC)/*.c)
PARSEROVRLSRCS += $(wildcard $(PARSEROVRLSRC)/*.s)

EXECOVRLSRCS := $(wildcard $(EXECOVRLSRC)/*.c)
EXECOVRLSRCS += $(wildcard $(EXECOVRLSRC)/*.s)
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatc.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/float.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatadd.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatsub.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatmult.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatdiv.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatutil.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatnorm.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatoutput.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatinput.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatround.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/int16c.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/leftpad.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/printz.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/readint16.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/writeint16.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/inputbuf.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/getline.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/parseint16.s

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(TOKENIZEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(PARSEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(EXECOVRLSRCS)))))

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

vpath $(TOKENIZEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(TOKENIZEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EXECOVRLSRC)/%.c
$(OBJDIR)/%.o: $(EXECOVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EXECOVRLSRC)/%.s
$(OBJDIR)/%.o: $(EXECOVRLSRC)/%.s | $(OBJDIR)
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

nested.petscii: nested.pas
	dos2unix < nested.pas | petcat -w2 -text -o nested.petscii

routines.petscii: routines.pas
	dos2unix < routines.pas | petcat -w2 -text -o routines.petscii

testforward.petscii: testforward.pas
	dos2unix < testforward.pas | petcat -w2 -text -o testforward.petscii

translate.petscii: translate.pas
	dos2unix < translate.pas | petcat -w2 -text -o translate.petscii

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) $(OBJECTS)

ifeq ($(TARGET),mega65)
$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii assign.pas testforward.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(TOKENIZEROVRLFILE) $(TOKENIZEROVRLFILE) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(EXECOVRLFILE) $(EXECOVRLFILE) \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write testforward.petscii testforward.pas,seq \
	-write translate.petscii translate.pas,seq \
	-write assign.pas assign.pas,seq
else
$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii testforward.petscii translate.petscii nested.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(TOKENIZEROVRLFILE) $(TOKENIZEROVRLFILE) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(EXECOVRLFILE) $(EXECOVRLFILE) \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write nested.petscii nested.pas,seq \
	-write testforward.petscii testforward.pas,seq \
	-write translate.petscii translate.pas,seq \
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
