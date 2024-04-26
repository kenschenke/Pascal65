SRCDIR := src
OBJDIR := obj
BINDIR := bin

PROGRAM := demolib
BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
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

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(PRGFILE)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJTARGETDIR):
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS) demolib.cfg
	ld65 $(LDFLAGS) -o $(PRGFILE) -C demolib.cfg $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINTARGETDIR)/*
