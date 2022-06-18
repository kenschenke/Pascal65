SRCDIR := src
OBJDIR := obj
BINDIR := bin
INTERPOVRLSRC := ../../overlays/interpreter

PROGRAM := interpreter
D81FILE := $(BINDIR)/$(PROGRAM).d81
OVRLFILE := $(PROGRAM).1
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

INTERPOVRLSRCS := $(wildcard $(INTERPOVRLSRC)/*.c)
INTERPOVRLSRCS += $(wildcard $(INTERPOVRLSRC)/*.s)

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(INTERPOVRLSRCS)))))

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

vpath $(INTERPOVRLSRC)/%.c
$(OBJDIR)/%.o: $(INTERPOVRLSRC)/%.c | $(OBJDIR)
	cl65 -t $(TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath $(INTERPOVRLSRC)/%.s
$(OBJDIR)/%.o: $(INTERPOVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	cl65 -t $(TARGET) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

$(D81FILE): $(BINDIR)/$(PROGRAM)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) -write $(BINDIR)/$(PROGRAM) $(PROGRAM) -write $(BINDIR)/$(OVRLFILE) $(OVRLFILE)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
