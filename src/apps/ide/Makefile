SRCDIR := src
OBJDIR := obj
BINDIR := bin
PARSEROVRLSRC := ../../overlays/parser
EXECOVRLSRC := ../../overlays/exec
EDITOROVRLSRC := ../../editor
SHAREDSRCDIR = ../../shared
LIBCSRCDIR = ../../mega65-libc/src
TARGETSRCDIR = $(SRCDIR)/$(TARGET)

PROGRAM := pascal65
D81FILE := $(BINDIR)/$(PROGRAM).d81
PARSEROVRLFILE := $(PROGRAM).1
EXECOVRLFILE := $(PROGRAM).2
EDITOROVRLFILE := $(PROGRAM).3
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64
c64_EMUCMD := x64sc -kernal kernal -VICIIdsize -autostart
c128_EMUCMD := x128 -kernal kernal -VICIIdsize -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)

mega65_CFLAGS = -D __MEGA65__ -I ../../include
CFLAGS = $($(TARGET)_CFLAGS) -I ../../mega65-libc/include
ASFLAGS =
LDFLAGS =

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.c)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.s)
SOURCES += $(SHAREDSRCDIR)/blocks.c
SOURCES += $(SHAREDSRCDIR)/chunks.c
SOURCES += $(SHAREDSRCDIR)/doscmd.s
SOURCES += $(SHAREDSRCDIR)/sendDosCmd.c

PARSEROVRLSRCS := $(wildcard $(PARSEROVRLSRC)/*.c)
PARSEROVRLSRCS += $(wildcard $(PARSEROVRLSRC)/*.s)

EXECOVRLSRCS := $(wildcard $(EXECOVRLSRC)/*.c)
EXECOVRLSRCS += $(wildcard $(EXECOVRLSRC)/*.s)

EDITOROVRLSRCS := $(wildcard $(EDITOROVRLSRC)/*.c)
EDITOROVRLSRCS += $(wildcard $(EDITOROVRLSRC)/*.s)
EDITOROVRLSRCS += $(wildcard $(LIBCSRCDIR)/*.c)
EDITOROVRLSRCS += $(wildcard $(LIBCSRCDIR)/*.s)

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

vpath $(EDITOROVRLSRC)/%.c
$(OBJDIR)/%.o: $(EDITOROVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EDITOROVRLSRC)/%.s
$(OBJDIR)/%.o: $(EDITOROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.c
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.s
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(OBJDIR)/blocks.o: $(SHAREDSRCDIR)/blocks.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

$(OBJDIR)/chunks.o: $(SHAREDSRCDIR)/chunks.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

$(OBJDIR)/sendDosCmd.o: $(SHAREDSRCDIR)/sendDosCmd.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

$(OBJDIR)/doscmd.o: $(SHAREDSRCDIR)/doscmd.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(CC65TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

$(D81FILE): $(BINDIR)/$(PROGRAM)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) -write $(BINDIR)/$(PROGRAM) $(PROGRAM) -write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) -write $(BINDIR)/$(EXECOVRLFILE) $(EXECOVRLFILE) -write $(BINDIR)/$(EDITOROVRLFILE) $(EDITOROVRLFILE)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
