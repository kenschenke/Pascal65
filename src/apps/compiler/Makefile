SRCDIR := src
OBJDIR := obj
BINDIR := bin
TOKENIZEROVRLSRC := ../../overlays/tokenizer
PARSEROVRLSRC := ../../overlays/parser
RESOLVEROVRLSRC := ../../overlays/resolver
TYPECHECKOVRLSRC := ../../overlays/typecheck
OBJCODEOVRLSRC := ../../overlays/objcode
LINKEROVRLSRC := ../../overlays/linker
SHAREDSRCDIR = ../../shared
SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks
SHAREDMEMBUFDIR = $(SHAREDSRCDIR)/membuf
SHAREDCODEGENDIR = $(SHAREDSRCDIR)/codegen
LIBCSRCDIR = ../../mega65-libc/src
LIBCOMMONDIR = ../../lib/common
TARGETSRCDIR = $(SRCDIR)/$(TARGET)

PROGRAM := compiler
TOKENIZEROVRLFILE := $(PROGRAM).1
PARSEROVRLFILE := $(PROGRAM).2
RESOLVEROVRLFILE := $(PROGRAM).3
TYPECHECKOVRLFILE := $(PROGRAM).4
OBJCODEOVRLFILE := $(PROGRAM).5
LINKEROVRLFILE := $(PROGRAM).6
CC65TARGET = c64

BINTARGETDIR := $(BINDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
CONFIG := cfg-$(TARGET).cfg
CFLAGS = $($(TARGET)_CFLAGS) -W error -D MAINPAS -O -I ../../include
c64_ASFLAGS =
c128_ASFLAGS =
mega65_ASFLAGS = --asm-define __MEGA65__
ASFLAGS = $($(TARGET)_ASFLAGS) --asm-include-dir ../../asminc
LDFLAGS = --mapfile compiler.map -C $(CONFIG)

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
SOURCES += $(wildcard $(LIBCOMMONDIR)/*.s)
ifeq ($(TARGET),mega65)
SOURCES += $(LIBCSRCDIR)/memory.c
endif

TOKENIZEROVRLSRCS := $(wildcard $(TOKENIZEROVRLSRC)/*.c)
TOKENIZEROVRLSRCS += $(wildcard $(TOKENIZEROVRLSRC)/*.s)

PARSEROVRLSRCS := $(wildcard $(PARSEROVRLSRC)/*.c)
PARSEROVRLSRCS += $(wildcard $(PARSEROVRLSRC)/*.s)

RESOLVEROVRLSRCS := $(wildcard $(RESOLVEROVRLSRC)/*.c)

TYPECHECKOVRLSRCS := $(wildcard $(TYPECHECKOVRLSRC)/*.c)

OBJCODEOVRLSRCS := $(wildcard $(OBJCODEOVRLSRC)/*.c)

LINKEROVRLSRCS := $(wildcard $(LINKEROVRLSRC)/*.c)
LINKEROVRLSRCS += $(wildcard $(LINKEROVRLSRC)/*.s)

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(TOKENIZEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(PARSEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(RESOLVEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(TYPECHECKOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(LINKEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(OBJCODEOVRLSRCS)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(PRGFILE)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

vpath %.c $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(TARGETSRCDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(TARGETSRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(TOKENIZEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(TOKENIZEROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(TOKENIZEROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(TOKENIZEROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(PARSEROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(PARSEROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(RESOLVEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(RESOLVEROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(RESOLVEROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(RESOLVEROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(TYPECHECKOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(TYPECHECKOVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY4 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(TYPECHECKOVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(TYPECHECKOVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY4 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(OBJCODEOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(OBJCODEOVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY5 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(OBJCODEOVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(OBJCODEOVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY5 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(LINKEROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(LINKEROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.c
$(OBJTARGETDIR)/%.o: $(LIBCSRCDIR)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.s
$(OBJTARGETDIR)/%.o: $(LIBCSRCDIR)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.c
$(OBJTARGETDIR)/%.o: $(SHAREDSRCDIR)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.s
$(OBJTARGETDIR)/%.o: $(SHAREDSRCDIR)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCHUNKSDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCHUNKSDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDMEMBUFDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDMEMBUFDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCODEGENDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCODEGENDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(PRGFILE) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINTARGETDIR)/*
	$(RM) $(PRGFILE)
