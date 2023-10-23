SRCDIR := src
OBJDIR := obj
BINDIR := bin
DRVDIR := ../../../drv
PARSEROVRLSRC := ../../overlays/parser
SEMANTICOVRLSRC := ../../overlays/semantic
OBJCODEOVRLSRC := ../../overlays/objcode
LINKEROVRLSRC := ../../overlays/linker
EDITOROVRLSRC := ../../overlays/editor
TOKENIZEROVRLSRC := ../../overlays/tokenizer
SHAREDSRCDIR = ../../shared
SHAREDCHUNKSDIR = ../../shared/chunks
SHAREDMEMBUFDIR = ../../shared/membuf
SHAREDCODEGENDIR = $(SHAREDSRCDIR)/codegen
LIBCSRCDIR = ../../mega65-libc/src
LIBCOMMONDIR = ../../lib/common
LIBRUNTIMEDIR = ../../lib/runtime/src
TARGETSRCDIR = $(SRCDIR)/$(TARGET)

PROGRAM := pascal65
D81FILE := $(BINDIR)/$(PROGRAM).d81
TOKENIZEROVRLFILE := $(PROGRAM).1
PARSEROVRLFILE := $(PROGRAM).2
SEMANTICOVRLFILE := $(PROGRAM).3
OBJCODEOVRLFILE := $(PROGRAM).4
LINKEROVRLFILE := $(PROGRAM).5
EDITOROVRLFILE := $(PROGRAM).6
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64
c64_EMUCMD = x64sc -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
c128_EMUCMD = x128 -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)
DRVFILE = $(DRVDIR)/$(TARGET)-reu.emd

mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
CFLAGS = $($(TARGET)_CFLAGS) -O -I ../../include
ifeq ($(TARGET),mega65)
ASFLAGS = --asm-include-dir ../../asminc
else
ASFLAGS = --asm-include-dir ../../asminc -D __MEGA65__
endif
LDFLAGS = --mapfile ide.map

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.c)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.c)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.s)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.c)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.s)
SOURCES += $(wildcard $(SHAREDCODEGENDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCODEGENDIR)/*.s)

PARSEROVRLSRCS := $(wildcard $(PARSEROVRLSRC)/*.c)
PARSEROVRLSRCS += $(wildcard $(PARSEROVRLSRC)/*.s)

TOKENIZEROVRLSRCS := $(wildcard $(TOKENIZEROVRLSRC)/*.c)
TOKENIZEROVRLSRCS += $(wildcard $(TOKENIZEROVRLSRC)/*.s)

SEMANTICOVRLSRCS := $(wildcard $(SEMANTICOVRLSRC)/*.c)

OBJCODEOVRLSRCS := $(wildcard $(OBJCODEOVRLSRC)/*.c)

LINKEROVRLSRCS := $(wildcard $(LINKEROVRLSRC)/*.c)

EDITOROVRLSRCS := $(wildcard $(EDITOROVRLSRC)/*.c)
EDITOROVRLSRCS += $(wildcard $(EDITOROVRLSRC)/*.s)
EDITOROVRLSRCS += $(wildcard $(EDITOROVRLSRC)/$(TARGET)/*.c)
EDITOROVRLSRCS += $(wildcard $(EDITOROVRLSRC)/$(TARGET)/*.s)
ifeq ($(TARGET),mega65)
EDITOROVRLSRCS += $(wildcard $(LIBCSRCDIR)/*.c)
EDITOROVRLSRCS += $(wildcard $(LIBCSRCDIR)/*.s)
endif
SOURCES += $(LIBRUNTIMEDIR)/exit.s
SOURCES += $(LIBRUNTIMEDIR)/inputbuf.s
SOURCES += $(LIBRUNTIMEDIR)/printz.s
SOURCES += $(LIBRUNTIMEDIR)/rterror.s
SOURCES += $(wildcard $(LIBCOMMONDIR)/*.s)

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(TOKENIZEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(PARSEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SEMANTICOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(OBJCODEOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(LINKEROVRLSRCS)))))
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

vpath $(SEMANTICOVRLSRC)/%.c
$(OBJDIR)/%.o: $(SEMANTICOVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SEMANTICOVRLSRC)/%.s
$(OBJDIR)/%.o: $(SEMANTICOVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(OBJCODEOVRLSRC)/%.c
$(OBJDIR)/%.o: $(OBJCODEOVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY4 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(OBJCODEOVRLSRC)/%.s
$(OBJDIR)/%.o: $(OBJCODEOVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY4 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(LINKEROVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY5 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(LINKEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY5 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/%.c
$(OBJDIR)/%.o: $(EDITOROVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/%.s
$(OBJDIR)/%.o: $(EDITOROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/$(TARGET)/%.c
$(OBJDIR)/%.o: $(EDITOROVRLSRC)/$(TARGET)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/$(TARGET)/%.s
$(OBJDIR)/%.o: $(EDITOROVRLSRC)/$(TARGET)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

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

vpath $(SHAREDMEMBUFDIR)/%.c
$(OBJDIR)/%.o: $(SHAREDMEMBUFDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDMEMBUFDIR)/%.s
$(OBJDIR)/%.o: $(SHAREDMEMBUFDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCODEGENDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCODEGENDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBRUNTIMEDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

abortmsgs.petscii: $(SHAREDSRCDIR)/abortmsgs.txt
	dos2unix < $(SHAREDSRCDIR)/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

errormsgs.petscii: $(SHAREDSRCDIR)/errormsgs.txt
	dos2unix < $(SHAREDSRCDIR)/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

runtimemsgs.petscii: $(SHAREDSRCDIR)/runtimemsgs.txt
	dos2unix < $(SHAREDSRCDIR)/runtimemsgs.txt | petcat -w2 -text -o runtimemsgs.petscii

help.petscii: help.txt
	dos2unix < help.txt | petcat -w2 -text -o help.petscii

title.petscii: title.txt
	dos2unix < title.txt | petcat -w2 -text -o title.petscii

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

ifeq ($(TARGET),mega65)
$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii help.petscii title.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(TOKENIZEROVRLFILE) $(TOKENIZEROVRLFILE) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(SEMANTICOVRLFILE) $(SEMANTICOVRLFILE) \
	-write $(BINDIR)/$(OBJCODEOVRLFILE) $(OBJCODEOVRLFILE) \
	-write $(BINDIR)/$(LINKEROVRLFILE) $(LINKEROVRLFILE) \
	-write $(BINDIR)/$(EDITOROVRLFILE) $(EDITOROVRLFILE) \
	-write runtime runtime \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write help.petscii help.txt,seq \
	-write title.petscii title.txt,seq
else
$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii help.petscii title.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(TOKENIZEROVRLFILE) $(TOKENIZEROVRLFILE) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(SEMANTICOVRLFILE) $(SEMANTICOVRLFILE) \
	-write $(BINDIR)/$(OBJCODEOVRLFILE) $(OBJCODEOVRLFILE) \
	-write $(BINDIR)/$(LINKEROVRLFILE) $(LINKEROVRLFILE) \
	-write $(BINDIR)/$(EDITOROVRLFILE) $(EDITOROVRLFILE) \
	-write $(DRVFILE) $(TARGET)-reu.emd,prg \
	-write runtime runtime \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write help.petscii help.txt,seq \
	-write title.petscii title.txt,seq
endif

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
