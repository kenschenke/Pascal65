SRCDIR := src
OBJDIR := obj
BINDIR := bin
EDITOROVRLSRC := ../../overlays/editor
EDITORFILESOVRLSRC := ../../overlays/editorfiles
COMPILERBIN := ../compiler/bin
SHAREDSRCDIR = ../../shared
SHAREDCHUNKSDIR = ../../shared/chunks
SHAREDMEMBUFDIR = ../../shared/membuf
SHAREDCODEGENDIR = $(SHAREDSRCDIR)/codegen
LIBCSRCDIR = ../../mega65-libc/src
LIBCOMMONDIR = ../../lib/common
LIBRUNTIMEDIR = ../../lib/runtime/src
TARGETSRCDIR = $(SRCDIR)/$(TARGET)

PROGRAM := pascal65
EDITOROVRLFILE := $(PROGRAM).1
EDITORFILESOVRLFILE := $(PROGRAM).2
CC65TARGET = c64

BINTARGETDIR := $(BINDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)

OBJTARGETDIR := $(OBJDIR)/$(TARGET)

mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
CFLAGS = $($(TARGET)_CFLAGS) -O -I ../../include
ifeq ($(TARGET),mega65)
ASFLAGS = --asm-include-dir ../../asminc --asm-define __MEGA65__
else
ASFLAGS = --asm-include-dir ../../asminc
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

EDITOROVRLSRCS := $(wildcard $(EDITOROVRLSRC)/*.c)
EDITOROVRLSRCS += $(wildcard $(EDITOROVRLSRC)/*.s)
EDITOROVRLSRCS += $(wildcard $(EDITOROVRLSRC)/$(TARGET)/*.c)
EDITOROVRLSRCS += $(wildcard $(EDITOROVRLSRC)/$(TARGET)/*.s)

EDITORFILESOVRLSRCS := $(wildcard $(EDITORFILESOVRLSRC)/*.c)
EDITORFILESOVRLSRCS += $(wildcard $(EDITORFILESOVRLSRC)/*.s)

SOURCES += $(LIBCOMMONDIR)/_printz.s
SOURCES += $(LIBCOMMONDIR)/exit.s
SOURCES += $(LIBCOMMONDIR)/getline.s
SOURCES += $(LIBCOMMONDIR)/inputbuf.s
SOURCES += $(LIBCOMMONDIR)/leftpad.s
SOURCES += $(LIBCOMMONDIR)/rterror.s
ifeq ($(TARGET),mega65)
SOURCES += $(wildcard $(LIBCSRCDIR)/*.c)
SOURCES += $(wildcard $(LIBCSRCDIR)/*.s)
endif

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(EDITOROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(EDITORFILESOVRLSRCS)))))

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

vpath $(EDITOROVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(EDITOROVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(EDITOROVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/$(TARGET)/%.c
$(OBJTARGETDIR)/%.o: $(EDITOROVRLSRC)/$(TARGET)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/$(TARGET)/%.s
$(OBJTARGETDIR)/%.o: $(EDITOROVRLSRC)/$(TARGET)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EDITORFILESOVRLSRC)/%.c
$(OBJTARGETDIR)/%.o: $(EDITORFILESOVRLSRC)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITORFILESOVRLSRC)/%.s
$(OBJTARGETDIR)/%.o: $(EDITORFILESOVRLSRC)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

ifeq ($(TARGET),mega65)
vpath $(LIBCSRCDIR)/%.c
$(OBJTARGETDIR)/%.o: $(LIBCSRCDIR)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.s
$(OBJTARGETDIR)/%.o: $(LIBCSRCDIR)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<
endif

vpath $(SHAREDSRCDIR)/%.c
$(OBJTARGETDIR)/%.o: $(SHAREDSRCDIR)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.s
$(OBJTARGETDIR)/%.o: $(SHAREDSRCDIR)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDCHUNKSDIR)/%.c
$(OBJTARGETDIR)/%.o: $(SHAREDCHUNKSDIR)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDCHUNKSDIR)/%.s
$(OBJTARGETDIR)/%.o: $(SHAREDCHUNKSDIR)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDMEMBUFDIR)/%.c
$(OBJTARGETDIR)/%.o: $(SHAREDMEMBUFDIR)/%.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(SHAREDMEMBUFDIR)/%.s
$(OBJTARGETDIR)/%.o: $(SHAREDMEMBUFDIR)/%.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCODEGENDIR)
$(OBJTARGETDIR)/%.o: %.c | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCODEGENDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath _printz.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/_printz.o: _printz.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath getline.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/getline.o: getline.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath inputbuf.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/inputbuf.o: inputbuf.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath int16.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/int16.o: int16.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath int16c.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/int16c.o: int16c.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath int16comp.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/int16comp.o: int16comp.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath int16sub.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/int16sub.o: int16sub.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath leftpad.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/leftpad.o: leftpad.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath writeint.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/writeint.o: writeint.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath uint16comp.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/uint16comp.o: uint16comp.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBRUNTIMEDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PRGFILE)
	$(RM) $(BINTARGETDIR)/*
