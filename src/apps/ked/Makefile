SRCDIR := src
OBJDIR := obj
BINDIR := bin
DRVDIR := ../../../drv

LIBCSRCDIR = ../../mega65-libc/src

PROGRAM := ked
D81FILE := $(BINDIR)/$(PROGRAM).d81
EDITOROVRLFILE := $(PROGRAM).1
EDITORFILEOVRLFILE := $(PROGRAM).2
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64
c64_EMUCMD = x64sc -warp -reu +sound -kernal kernal -VICIIdsize +confirmonexit -autostart
c128_EMUCMD := x128 -kernal kernal -VICIIdsize -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)
DRVFILE = $(DRVDIR)/$(TARGET)-reu.emd

EDITORSRCDIR = ../../overlays/editor
EDITORFILESRCDIR = ../../overlays/editorfiles
TARGETSRCDIR = $(EDITORSRCDIR)/$(TARGET)
SHAREDSRCDIR = ../../shared
SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks
SHAREDMEMBUFDIR = $(SHAREDSRCDIR)/membuf
LIBCOMMONDIR = ../../lib/common
LIBRUNTIMEDIR = ../../lib/runtime/src
IDESRCDIR = ../ide/src

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include -I ../../include
CFLAGS = $($(TARGET)_CFLAGS) -O -I ../../include
ifeq ($(TARGET),mega65)
ASFLAGS = --asm-include-dir ../../asminc --asm-define __MEGA65__
else
ASFLAGS = --asm-include-dir ../../asminc
endif
LDFLAGS =

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(SRCDIR)/*.s)
ifeq ($(TARGET),mega65)
SOURCES += $(wildcard $(SRCDIR)/mega65/*.c)
SOURCES += $(wildcard $(SRCDIR)/mega65/*.s)
endif
SOURCES += $(wildcard $(TARGETSRCDIR)/*.c)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.s)
SOURCES += $(wildcard $(EDITORSRCDIR)/*.c)
SOURCES += $(wildcard $(EDITORSRCDIR)/*.s)
SOURCES += $(wildcard $(EDITORFILESRCDIR)/*.c)
SOURCES += $(wildcard $(EDITORFILESRCDIR)/*.s)
ifeq ($(TARGET),mega65)
SOURCES += $(wildcard $(LIBCSRCDIR)/*.c)
SOURCES += $(wildcard $(LIBCSRCDIR)/*.s)
endif
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.s)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.c)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.s)
SOURCES += $(wildcard $(LIBCOMMONDIR)/*.s)
SOURCES += $(SHAREDSRCDIR)/doscmd.s
SOURCES += $(SHAREDSRCDIR)/sendDosCmd.c
SOURCES += $(LIBRUNTIMEDIR)/exit.s
SOURCES += $(LIBRUNTIMEDIR)/inputbuf.s
SOURCES += $(LIBRUNTIMEDIR)/printz.s
SOURCES += $(LIBRUNTIMEDIR)/rterror.s
SOURCES += $(IDESRCDIR)/idecommon.s

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(D81FILE) help.petscii

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

vpath $(SRCDIR)/%.c
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SRCDIR)/%.s
$(OBJDIR)/%.o: $(SRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

ifeq ($(TARGET),mega65)
vpath $(SRCDIR)/mega65/%.c
$(OBJDIR)/%.o: $(SRCDIR)/mega65/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SRCDIR)/mega65/%.s
$(OBJDIR)/%.o: $(SRCDIR)/mega65/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<
endif

vpath $(TARGETSRCDIR)/%.c
$(OBJDIR)/%.o: $(TARGETSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(TARGETSRCDIR)/%.s
$(OBJDIR)/%.o: $(TARGETSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EDITORSRCDIR)/%.c
$(OBJDIR)/%.o: $(EDITORSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITORSRCDIR)/%.s
$(OBJDIR)/%.o: $(EDITORSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EDITORFILESRCDIR)/%.c
$(OBJDIR)/%.o: $(EDITORFILESRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITORFILESRCDIR)/%.s
$(OBJDIR)/%.o: $(EDITORFILESRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.c
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.s
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.s | $(OBJDIR)
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

vpath $(LIBCOMMONDIR)/%.s
$(OBJDIR)/%.o: $(LIBCOMMONDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LIBRUNTIMEDIR)/%.s
$(OBJDIR)/%.o: $(LIBRUNTIMEDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.c
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.s
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(IDESRCDIR)/%.s
$(OBJDIR)/%.o: $(IDESRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

help.petscii: help.txt
	dos2unix < help.txt | petcat -w2 -text -o help.petscii

license.petscii: ../../../LICENSE
	dos2unix < $< | petcat -w3 -text -o license.petscii

title.petscii: title.txt
	dos2unix < title.txt | petcat -w2 -text -o title.petscii

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

ifeq ($(TARGET),mega65)
$(D81FILE): $(BINDIR)/$(PROGRAM) help.petscii license.petscii title.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) -write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write help.petscii help.txt,seq \
	-write $(BINDIR)/$(EDITOROVRLFILE) $(EDITOROVRLFILE) \
	-write $(BINDIR)/$(EDITORFILEOVRLFILE) $(EDITORFILEOVRLFILE) \
	-write license.petscii license,seq \
	-write title.petscii title.txt,seq
else
$(D81FILE): $(BINDIR)/$(PROGRAM) help.petscii license.petscii title.petscii
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) -write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write help.petscii help.txt,seq \
	-write $(BINDIR)/$(EDITOROVRLFILE) $(EDITOROVRLFILE) \
	-write $(BINDIR)/$(EDITORFILEOVRLFILE) $(EDITORFILEOVRLFILE) \
	-write license.petscii license,seq \
	-write title.petscii title.txt,seq \
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
