SRCDIR := src
OBJDIR := obj
BINDIR := bin

LIBCSRCDIR = ../../mega65-libc/src

PROGRAM := ked
D81FILE := $(BINDIR)/$(PROGRAM).d81
COMPOVRLFILE := $(PROGRAM).1
INTERPOVRLFILE := $(PROGRAM).2
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64
c64_EMUCMD := x64sc -kernal kernal -VICIIdsize -autostart
c128_EMUCMD := x128 -kernal kernal -VICIIdsize -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)

TARGETSRCDIR = $(SRCDIR)/$(TARGET)
EDITORSRCDIR = ../../editor
SHAREDSRCDIR = ../../shared

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../include
CFLAGS = $($(TARGET)_CFLAGS) -O -I ../../mega65-libc/include
ASFLAGS = --asm-include-dir ../../asminc
LDFLAGS =

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.c)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.s)
SOURCES += $(wildcard $(EDITORSRCDIR)/*.c)
SOURCES += $(wildcard $(EDITORSRCDIR)/*.s)
SOURCES += $(wildcard $(LIBCSRCDIR)/*.c)
SOURCES += $(wildcard $(LIBCSRCDIR)/*.s)
SOURCES += $(SHAREDSRCDIR)/blocks.c
SOURCES += $(SHAREDSRCDIR)/chunks.c
SOURCES += $(SHAREDSRCDIR)/doscmd.s
SOURCES += $(SHAREDSRCDIR)/sendDosCmd.c
SOURCES += $(SHAREDSRCDIR)/allocChunk.s
SOURCES += $(SHAREDSRCDIR)/chunkGetBlock.s
SOURCES += $(SHAREDSRCDIR)/freeChunk.s
SOURCES += $(SHAREDSRCDIR)/getAvailChunks.s
SOURCES += $(SHAREDSRCDIR)/initChunkStorage.s
SOURCES += $(SHAREDSRCDIR)/retrieveChunk.s
SOURCES += $(SHAREDSRCDIR)/storeChunk.s

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(D81FILE) help.petscii

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

vpath %.c $(EDITORSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(EDITORSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(LIBCSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(LIBCSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/blocks.o: $(SHAREDSRCDIR)/blocks.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

$(OBJDIR)/chunks.o: $(SHAREDSRCDIR)/chunks.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

$(OBJDIR)/sendDosCmd.o: $(SHAREDSRCDIR)/sendDosCmd.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

$(OBJDIR)/doscmd.o: $(SHAREDSRCDIR)/doscmd.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/allocChunk.o: $(SHAREDSRCDIR)/allocChunk.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/chunkGetBlock.o: $(SHAREDSRCDIR)/chunkGetBlock.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/freeChunk.o: $(SHAREDSRCDIR)/freeChunk.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/getAvailChunks.o: $(SHAREDSRCDIR)/getAvailChunks.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/initChunkStorage.o: $(SHAREDSRCDIR)/initChunkStorage.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/retrieveChunk.o: $(SHAREDSRCDIR)/retrieveChunk.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/storeChunk.o: $(SHAREDSRCDIR)/storeChunk.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

help.petscii: help.txt
	dos2unix < help.txt | petcat -text -o help.petscii

license.petscii: ../../../LICENSE
	dos2unix < $< | petcat -text -o license.petscii

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

$(D81FILE): $(BINDIR)/$(PROGRAM) help.petscii license.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) -write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write help.petscii help.txt,seq \
	-write license.petscii license,seq

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
