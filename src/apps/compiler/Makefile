SRCDIR := src
OBJDIR := obj
BINDIR := bin
TOKENIZEROVRLSRC := ../../overlays/tokenizer
PARSEROVRLSRC := ../../overlays/parser
RESOLVEROVRLSRC := ../../overlays/resolver
TYPECHECKOVRLSRC := ../../overlays/typecheck
LINKEROVRLSRC := ../../overlays/linker
ICODEOVRLSRC := ../../overlays/icode
ICODEGENOVRLSRC := ../../overlays/icodegen
SHAREDSRCDIR = ../../shared
SHAREDCODEGENDIR = $(SHAREDSRCDIR)/codegen
LIBCSRCDIR = ../../mega65-libc/src
LIBCOMMONDIR = ../../lib/common
TARGETSRCDIR = $(SRCDIR)/$(TARGET)

ifdef GCC
ICODEDUMPSRC := ../../overlays/icodedump
endif

ifdef GCC

SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks/gnuc
SHAREDMEMBUFDIR = $(SHAREDSRCDIR)/membuf/gnuc

else

SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks
SHAREDMEMBUFDIR = $(SHAREDSRCDIR)/membuf

endif

PROGRAM := compiler
TOKENIZEROVRLFILE := $(PROGRAM).1
PARSEROVRLFILE := $(PROGRAM).2
RESOLVEROVRLFILE := $(PROGRAM).3
TYPECHECKOVRLFILE := $(PROGRAM).4
ICODEOVRLFILE := $(PROGRAM).5
ICODEGENOVRLFILE := $(PROGRAM).6
LINKEROVRLFILE := $(PROGRAM).7
CC65TARGET = c64

BINTARGETDIR := $(BINDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
CONFIG := cfg-$(TARGET).cfg
c64_ASFLAGS =
c128_ASFLAGS =
mega65_ASFLAGS = --asm-define __MEGA65__
ASFLAGS = $($(TARGET)_ASFLAGS) --asm-include-dir ../../asminc

ifdef GCC
CC = gcc
CFLAGS = $($(TARGET)_CFLAGS) -c -fpack-struct=1 -m32 -rdynamic -g -I ../../include
LDFLAGS = -m32 -rdynamic -g
else
CC = cl65
CFLAGS = $($(TARGET)_CFLAGS) -t $(CC65TARGET) -c --create-dep $(@:.o=.d) -W error -O -I ../../include
LDFLAGS = -t $(CC65TARGET) --mapfile compiler.map -C $(CONFIG)
endif

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.c)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.c)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCODEGENDIR)/*.c)

TOKENIZEROVRLSRCS := $(wildcard $(TOKENIZEROVRLSRC)/*.c)

PARSEROVRLSRCS := $(wildcard $(PARSEROVRLSRC)/*.c)

RESOLVEROVRLSRCS := $(wildcard $(RESOLVEROVRLSRC)/*.c)

TYPECHECKOVRLSRCS := $(wildcard $(TYPECHECKOVRLSRC)/*.c)

ICODEOVRLSRCS := $(wildcard $(ICODEOVRLSRC)/*.c)

ICODEGENOVRLSRCS := $(wildcard $(ICODEGENOVRLSRC)/*.c)

LINKEROVRLSRCS := $(wildcard $(LINKEROVRLSRC)/*.c)

ifdef GCC
SOURCES += $(wildcard $(ICODEDUMPSRC)/*.c)
endif

ifdef GCC
SOURCES += $(wildcard $(SHAREDSRCDIR)/gnuc/*.c)
endif

ifndef GCC

ifeq ($(TARGET),mega65)
SOURCES += $(LIBCSRCDIR)/memory.c
endif

SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.s)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.s)
SOURCES += $(wildcard $(SHAREDCODEGENDIR)/*.s)
SOURCES += $(wildcard $(LIBCOMMONDIR)/*.s)
PARSEROVRLSRCS += $(wildcard $(PARSEROVRLSRC)/*.s)
LINKEROVRLSRCS += $(wildcard $(LINKEROVRLSRC)/*.s)
TOKENIZEROVRLSRCS += $(wildcard $(TOKENIZEROVRLSRC)/*.s)

endif

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(TOKENIZEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(PARSEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(RESOLVEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(TYPECHECKOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(LINKEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(ICODEOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(ICODEGENOVRLSRCS)))))

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
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(TARGETSRCDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(TARGETSRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

ifdef GCC

vpath $(TOKENIZEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(TOKENIZEROVRLSRC)/%.c | $(OBJTARGETDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(PARSEROVRLSRC)/%.c | $(OBJTARGETDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(RESOLVEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(RESOLVEROVRLSRC)/%.c | $(OBJTARGETDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(TYPECHECKOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(TYPECHECKOVRLSRC)/%.c | $(OBJTARGETDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(ICODEOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(ICODEOVRLSRC)/%.c | $(OBJTARGETDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(ICODEGENOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(ICODEGENOVRLSRC)/%.c | $(OBJTARGETDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(ICODEDUMPSRC)/%.c
$(OBJTARGETDIR)/%.o: $(ICODEDUMPSRC)/%.c | $(OBJTARGETDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(LINKEROVRLSRC)/%.c | $(OBJTARGETDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/gnuc/%.c
$(OBJTARGETDIR)/%.o: $(SHAREDSRCDIR)/gnuc/%.c | $(OBJDIR)
	gcc $(CFLAGS) -o $@ $<

else

vpath $(TOKENIZEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(TOKENIZEROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 $(CFLAGS) -o $@ $<

vpath $(TOKENIZEROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(TOKENIZEROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(PARSEROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(PARSEROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(RESOLVEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(RESOLVEROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 $(CFLAGS) -o $@ $<

vpath $(RESOLVEROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(RESOLVEROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(TYPECHECKOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(TYPECHECKOVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY4 $(CFLAGS) -o $@ $<

vpath $(TYPECHECKOVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(TYPECHECKOVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY4 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(ICODEOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(ICODEOVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY5 $(CFLAGS) -o $@ $<

vpath $(ICODEOVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(ICODEOVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY5 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(ICODEGENOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(ICODEGENOVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 $(CFLAGS) -o $@ $<

vpath $(ICODEGENOVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(ICODEGENOVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(LINKEROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY7 $(CFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(LINKEROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY7 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

endif

vpath $(LIBCSRCDIR)/%.c
$(OBJTARGETDIR)/%.o: $(LIBCSRCDIR)/%.c | $(OBJTARGETDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.s
$(OBJTARGETDIR)/%.o: $(LIBCSRCDIR)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.c
$(OBJTARGETDIR)/%.o: $(SHAREDSRCDIR)/%.c | $(OBJTARGETDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.s
$(OBJTARGETDIR)/%.o: $(SHAREDSRCDIR)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCHUNKSDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCHUNKSDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDMEMBUFDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDMEMBUFDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCODEGENDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCODEGENDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(PRGFILE) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINTARGETDIR)/*
	$(RM) $(PRGFILE)
