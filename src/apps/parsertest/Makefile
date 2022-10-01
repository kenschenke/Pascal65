SRCDIR := src
OBJDIR := obj
BINDIR := bin

LIBCSRCDIR = ../../mega65-libc/src

PROGRAM := icodetest
D81FILE := $(BINDIR)/$(PROGRAM).d81
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64
EMUCMD = xmega65 -besure -go64 -autoload -8

SHAREDSRCDIR = ../../shared
SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks
SHAREDICODEDIR = $(SHAREDSRCDIR)/icode
PARSERSRCDIR = ../../overlays/parser

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -D __TEST__ -I ../../include
CFLAGS = $($(TARGET)_CFLAGS) -O -I ../../mega65-libc/include
ASFLAGS = --asm-include-dir ../../asminc
LDFLAGS = --mapfile parsertest.map

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(PARSERSRCDIR)/*.c)
SOURCES += $(wildcard $(PARSERSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.s)
SOURCES += $(wildcard $(SHAREDICODEDIR)/*.c)
SOURCES += $(wildcard $(SHAREDICODEDIR)/*.s)
SOURCES += $(SHAREDSRCDIR)/common.c
SOURCES += $(SHAREDSRCDIR)/error.c
SOURCES += $(SHAREDSRCDIR)/symtab.c
SOURCES += $(SHAREDSRCDIR)/types.c
SOURCES += $(LIBCSRCDIR)/memory.c

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

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

vpath %.c $(PARSERSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(PARSERSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
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

vpath %.c $(LIBCSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(LIBCSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) $(OBJECTS)

abortmsgs.petscii: $(SHAREDSRCDIR)/abortmsgs.txt
	dos2unix < $(SHAREDSRCDIR)/abortmsgs.txt | petcat -text -o abortmsgs.petscii

errormsgs.petscii: $(SHAREDSRCDIR)/errormsgs.txt
	dos2unix < $(SHAREDSRCDIR)/errormsgs.txt | petcat -text -o errormsgs.petscii

runtimemsgs.petscii: $(SHAREDSRCDIR)/runtimemsgs.txt
	dos2unix < $(SHAREDSRCDIR)/runtimemsgs.txt | petcat -text -o runtimemsgs.petscii

scopeerr.petscii: scopeerr.pas
	dos2unix < $(SHAREDSRCDIR)/scopeerr.pas | petcat -text -o scopeerr.petscii

$(D81FILE): $(BINDIR)/$(PROGRAM) abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii scopeerr.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write scopeerr.pas scopeerr.pas,seq

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
