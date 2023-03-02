SRCDIR := src
OBJDIR := obj
BINDIR := bin
DRVDIR := ../../../drv
PARSEROVRLSRC := ../../overlays/parser
EXECOVRLSRC := ../../overlays/exec
EDITOROVRLSRC := ../../editor
SHAREDSRCDIR = ../../shared
SHAREDCHUNKSDIR = ../../shared/chunks
SHAREDICODEDIR = ../../shared/icode
SHAREDMEMBUFDIR = ../../shared/membuf
LIBCSRCDIR = ../../mega65-libc/src
LIBCOMMONDIR = ../../lib/common
TARGETSRCDIR = $(SRCDIR)/$(TARGET)

PROGRAM := pascal65
D81FILE := $(BINDIR)/$(PROGRAM).d81
PARSEROVRLFILE := $(PROGRAM).1
EXECOVRLFILE := $(PROGRAM).2
EDITOROVRLFILE := $(PROGRAM).3
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := c128
CC65TARGET = c128
c64_EMUCMD = x64sc -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
c128_EMUCMD = x128 -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)
DRVFILE = $(DRVDIR)/$(TARGET)-reu.emd

mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
CFLAGS = $($(TARGET)_CFLAGS) -O -I ../../include
ASFLAGS = --asm-include-dir ../../asminc
LDFLAGS = --mapfile ide.map

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
SOURCES += $(LIBCOMMONDIR)/float.s
SOURCES += $(LIBCOMMONDIR)/floatinput.s
SOURCES += $(LIBCOMMONDIR)/floatnorm.s
SOURCES += $(LIBCOMMONDIR)/floatutil.s
SOURCES += $(LIBCOMMONDIR)/int16.s
SOURCES += $(LIBCOMMONDIR)/int16comp.s
SOURCES += $(LIBCOMMONDIR)/parseint16.s
SOURCES += $(LIBCOMMONDIR)/readint16.s
SOURCES += $(LIBCOMMONDIR)/uint16comp.s
SOURCES += $(LIBCOMMONDIR)/writeint16.s
# SOURCES += $(wildcard $(LIBCOMMONDIR)/*.c)
# SOURCES += $(wildcard $(LIBCOMMONDIR)/*.s)

PARSEROVRLSRCS := $(wildcard $(PARSEROVRLSRC)/*.c)
PARSEROVRLSRCS += $(wildcard $(PARSEROVRLSRC)/*.s)

EXECOVRLSRCS := $(wildcard $(EXECOVRLSRC)/*.c)
EXECOVRLSRCS += $(wildcard $(EXECOVRLSRC)/*.s)
#EXECOVRLSRCS += $(LIBCOMMONDIR)/float.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatadd.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatc.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatcomp.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatdiv.s
#EXECOVRLSRCS += $(LIBCOMMONDIR)/floatinput.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatmult.s
#EXECOVRLSRCS += $(LIBCOMMONDIR)/floatnorm.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatoutput.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatround.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/floatsub.s
#EXECOVRLSRCS += $(LIBCOMMONDIR)/floatutil.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/getline.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/inputbuf.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/leftpad.s
EXECOVRLSRCS += $(LIBCOMMONDIR)/printz.s
# EXECOVRLSRCS += $(LIBCOMMONDIR)/int16.s

EDITOROVRLSRCS := $(wildcard $(EDITOROVRLSRC)/*.c)
EDITOROVRLSRCS += $(wildcard $(EDITOROVRLSRC)/*.s)
ifeq ($(TARGET),mega65)
EDITOROVRLSRCS += $(wildcard $(LIBCSRCDIR)/*.c)
EDITOROVRLSRCS += $(wildcard $(LIBCSRCDIR)/*.s)
endif

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(PARSEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(EXECOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(EDITOROVRLSRCS)))))

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

vpath $(PARSEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EXECOVRLSRC)/%.c
$(OBJDIR)/%.o: $(EXECOVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EXECOVRLSRC)/%.s
$(OBJDIR)/%.o: $(EXECOVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LIBCOMMONDIR)/%.c
$(OBJDIR)/%.o: $(LIBCOMMONDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LIBCOMMONDIR)/%.s
$(OBJDIR)/%.o: $(LIBCOMMONDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/%.c
$(OBJDIR)/%.o: $(EDITOROVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/%.s
$(OBJDIR)/%.o: $(EDITOROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

ifeq ($(TARGET),mega65)
vpath $(LIBCSRCDIR)/%.c
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.s
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<
endif

vpath $(SHAREDSRCDIR)/%.c
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.s
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDCHUNKSDIR)/%.c
$(OBJDIR)/%.o: $(SHAREDCHUNKSDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDCHUNKSDIR)/%.s
$(OBJDIR)/%.o: $(SHAREDCHUNKSDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDICODEDIR)/%.c
$(OBJDIR)/%.o: $(SHAREDICODEDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDICODEDIR)/%.s
$(OBJDIR)/%.o: $(SHAREDICODEDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDMEMBUFDIR)/%.c
$(OBJDIR)/%.o: $(SHAREDMEMBUFDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDMEMBUFDIR)/%.s
$(OBJDIR)/%.o: $(SHAREDMEMBUFDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

abortmsgs.petscii: $(SHAREDSRCDIR)/abortmsgs.txt
	dos2unix < $(SHAREDSRCDIR)/abortmsgs.txt | petcat -text -o abortmsgs.petscii

errormsgs.petscii: $(SHAREDSRCDIR)/errormsgs.txt
	dos2unix < $(SHAREDSRCDIR)/errormsgs.txt | petcat -text -o errormsgs.petscii

runtimemsgs.petscii: $(SHAREDSRCDIR)/runtimemsgs.txt
	dos2unix < $(SHAREDSRCDIR)/runtimemsgs.txt | petcat -text -o runtimemsgs.petscii

help.petscii: help.txt
	dos2unix < help.txt | petcat -text -o help.petscii

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

ifeq ($(TARGET),mega65)
$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(EXECOVRLFILE) $(EXECOVRLFILE) \
	-write $(BINDIR)/$(EDITOROVRLFILE) $(EDITOROVRLFILE) \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq
else
$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii help.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(EXECOVRLFILE) $(EXECOVRLFILE) \
	-write $(BINDIR)/$(EDITOROVRLFILE) $(EDITOROVRLFILE) \
	-write $(DRVFILE) $(TARGET)-reu.emd,prg \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write help.petscii help.txt,seq
endif

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
