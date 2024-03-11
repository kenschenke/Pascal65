SRCDIR := src
OBJDIR := obj
BINDIR := bin

TARGET := mega65
PROGRAM := debug
BINTARGETDIR := $(BINDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)
CC65TARGET = c64

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D __MEGA65__
else
ASFLAGS = -I ../../asminc
endif
LDFLAGS =

SOURCES += $(wildcard $(SRCDIR)/*.s)

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINTARGETDIR) $(OBJDIR) $(PRGFILE)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS) debug.cfg
	ld65 $(LDFLAGS) -o $(PRGFILE) -C debug.cfg $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINTARGETDIR)/*
