SRCDIR := src
OBJDIR := obj
BINDIR := bin
LIBCOMMONDIR := ../common

PROGRAM := runtime
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D RUNTIME -D __MEGA65__
else
ASFLAGS = -I ../../asminc -D RUNTIME
endif
LDFLAGS = --mapfile runtime.map

# SOURCES += $(SRCDIR)/abs.s
# SOURCES += $(SRCDIR)/add.s
SOURCES += $(SRCDIR)/addysp.s
# SOURCES += $(SRCDIR)/array.s
# SOURCES += $(SRCDIR)/assign.s
# SOURCES += $(SRCDIR)/comp.s
# SOURCES += $(SRCDIR)/converttypes.s
SOURCES += $(SRCDIR)/clearinputbuf.s
SOURCES += $(SRCDIR)/decsp4.s
# SOURCES += $(SRCDIR)/divide.s
# SOURCES += $(SRCDIR)/divint.s
SOURCES += $(SRCDIR)/exit.s
SOURCES += $(SRCDIR)/incsp4.s
SOURCES += $(SRCDIR)/int8.s
SOURCES += $(SRCDIR)/int16.s
SOURCES += $(SRCDIR)/int16comp.s
SOURCES += $(SRCDIR)/int32.s
SOURCES += $(SRCDIR)/int32comp.s
SOURCES += $(SRCDIR)/int32sub.s
# SOURCES += $(SRCDIR)/inputbuf.s
SOURCES += $(SRCDIR)/isalpha.s
SOURCES += $(SRCDIR)/jmptbl.s
SOURCES += $(SRCDIR)/leftpad.s
SOURCES += $(SRCDIR)/loadaddr.s
# SOURCES += $(SRCDIR)/math.s
# SOURCES += $(SRCDIR)/memcopy.s
SOURCES += $(SRCDIR)/memheap.s
# SOURCES += $(SRCDIR)/mod.s
# SOURCES += $(SRCDIR)/multiply.s
# SOURCES += $(SRCDIR)/negate.s
SOURCES += $(SRCDIR)/popax.s
SOURCES += $(SRCDIR)/popeax.s
# SOURCES += $(SRCDIR)/pred.s
SOURCES += $(SRCDIR)/printz.s
# SOURCES += $(SRCDIR)/pushax.s
SOURCES += $(SRCDIR)/pusheax.s
# SOURCES += $(SRCDIR)/readFloatFromInput.s
# SOURCES += $(SRCDIR)/readIntFromInput.s
# SOURCES += $(SRCDIR)/record.s
SOURCES += $(SRCDIR)/rterror.s
SOURCES += $(SRCDIR)/rtstack.s
# SOURCES += $(SRCDIR)/sqr.s
# SOURCES += $(SRCDIR)/succ.s
# SOURCES += $(SRCDIR)/subtract.s
SOURCES += $(SRCDIR)/strcase.s
SOURCES += $(SRCDIR)/tenstable.s
SOURCES += $(SRCDIR)/trim.s
SOURCES += $(SRCDIR)/uint32comp.s
SOURCES += $(SRCDIR)/writebool.s
SOURCES += $(SRCDIR)/writechar.s
SOURCES += $(SRCDIR)/writeint.s
SOURCES += $(SRCDIR)/writestring.s
SOURCES += $(SRCDIR)/writevalue.s
# SOURCES += $(LIBCOMMONDIR)/float.s
# SOURCES += $(LIBCOMMONDIR)/floatabs.s
# SOURCES += $(LIBCOMMONDIR)/floatadd.s
# SOURCES += $(LIBCOMMONDIR)/floatcomp.s
# SOURCES += $(LIBCOMMONDIR)/floatdiv.s
# SOURCES += $(LIBCOMMONDIR)/floatinput.s
# SOURCES += $(LIBCOMMONDIR)/floatmult.s
# SOURCES += $(LIBCOMMONDIR)/floatneg.s
# SOURCES += $(LIBCOMMONDIR)/floatnorm.s
# SOURCES += $(LIBCOMMONDIR)/floatoutput.s
# SOURCES += $(LIBCOMMONDIR)/floatround.s
# SOURCES += $(LIBCOMMONDIR)/floatsqr.s
# SOURCES += $(LIBCOMMONDIR)/floatsub.s
# SOURCES += $(LIBCOMMONDIR)/floatutil.s
# SOURCES += $(LIBCOMMONDIR)/getline.s
# SOURCES += $(LIBCOMMONDIR)/int.s
# SOURCES += $(LIBCOMMONDIR)/int16add.s
# SOURCES += $(LIBCOMMONDIR)/int16div.s
# SOURCES += $(LIBCOMMONDIR)/int16mod.s
# SOURCES += $(LIBCOMMONDIR)/int16mult.s
# SOURCES += $(LIBCOMMONDIR)/int16sub.s
# SOURCES += $(LIBCOMMONDIR)/int32add.s
# SOURCES += $(LIBCOMMONDIR)/int32div.s
# SOURCES += $(LIBCOMMONDIR)/int32mult.s
# SOURCES += $(LIBCOMMONDIR)/int32sqr.s
# SOURCES += $(LIBCOMMONDIR)/int8.s
# SOURCES += $(LIBCOMMONDIR)/int8add.s
# SOURCES += $(LIBCOMMONDIR)/int8comp.s
# SOURCES += $(LIBCOMMONDIR)/int8div.s
# SOURCES += $(LIBCOMMONDIR)/int8mult.s
# SOURCES += $(LIBCOMMONDIR)/int8sub.s
# SOURCES += $(LIBCOMMONDIR)/readint16.s
# SOURCES += $(LIBCOMMONDIR)/readint32.s
# SOURCES += $(LIBCOMMONDIR)/strtofloat.s
# SOURCES += $(LIBCOMMONDIR)/uint16comp.s
# SOURCES += $(LIBCOMMONDIR)/uint16mult.s
# SOURCES += $(LIBCOMMONDIR)/uint32mult.s

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(BINDIR)/$(PROGRAM)

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	ld65 $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
