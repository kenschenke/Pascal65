SRCDIR := src
PARSERSRCDIR := ../../overlays/parser
EXECSRCDIR := ../../overlays/exec
SHAREDSRCDIR := ../../shared
OBJDIR := obj
BINDIR := bin
INPUTFILE := expr1.txt

PROGRAM := interpreter
D81FILE := $(BINDIR)/$(PROGRAM).d81
OVRL1FILE := $(PROGRAM).1
OVRL2FILE := $(PROGRAM).2
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := c128
c64_EMUCMD := x64sc -kernal kernal -VICIIdsize -autostart
c128_EMUCMD := x128 -kernal kernal -VICIIdsize -autostart
EMUCMD = $($(TARGET)_EMUCMD)

CFLAGS = -I ../../include
ASFLAGS =
LDFLAGS =

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.c)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.s)

PARSERSRCS := $(wildcard $(PARSERSRCDIR)/*.c)
PARSERSRCS += $(wildcard $(PARSERSRCDIR)/*.s)

EXECSRCS := $(wildcard $(EXECSRCDIR)/*.c)
EXECSRCS += $(wildcard $(EXECSRCDIR)/*.s)

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(PARSERSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(EXECSRCS)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(D81FILE)

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@
	
vpath %.c $(SRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(PARSERSRCDIR)/%.c
$(OBJDIR)/%.o: $(PARSERSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(PARSERSRCDIR)/%.s
$(OBJDIR)/%.o: $(PARSERSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(EXECSRCDIR)/%.c
$(OBJDIR)/%.o: $(EXECSRCDIR)/%.c | $(OBJDIR)
	cl65 -t $(TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(EXECSRCDIR)/%.s
$(OBJDIR)/%.o: $(EXECSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

$(D81FILE): $(BINDIR)/$(PROGRAM) $(INPUTFILE)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) -write $(BINDIR)/$(PROGRAM) $(PROGRAM) -write $(BINDIR)/$(OVRL1FILE) $(OVRL1FILE) -write $(BINDIR)/$(OVRL2FILE) $(OVRL2FILE) -write $(INPUTFILE) expr1.in,s

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
