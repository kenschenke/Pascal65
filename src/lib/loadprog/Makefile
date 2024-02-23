SRCDIR := src
OBJDIR := obj
BINDIR := bin

PROGRAM := loadprog
CC65TARGET = c64

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)

PRGFILE := $(BINTARGETDIR)/$(PROGRAM)

ASFLAGS = -I ../../asminc
ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D __MEGA65__
endif
LDFLAGS =

SOURCES += $(wildcard $(SRCDIR)/*.s)

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

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

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS) $(BINTARGETDIR)
	ld65 $(LDFLAGS) -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINTARGETDIR)/*
